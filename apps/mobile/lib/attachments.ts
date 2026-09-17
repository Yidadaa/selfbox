import { randomUUID } from "expo-crypto";
import { Directory, File, Paths } from "expo-file-system";
import type { ImagePickerAsset } from "expo-image-picker";
import { type ImageAttachment, imageSchema } from "@/db/payload";

const directory = () => new Directory(Paths.document, "attachments");

export function attachmentUri(image: ImageAttachment) {
  return new File(directory(), imageSchema.parse(image).file).uri;
}

export function importAttachment(
  asset: Pick<ImagePickerAsset, "uri" | "width" | "height" | "mimeType">,
): ImageAttachment {
  const folder = directory();
  folder.create({ idempotent: true, intermediates: true });
  const extension = asset.mimeType?.split("/")[1]?.toLowerCase();
  const suffix =
    extension &&
    ["jpg", "jpeg", "png", "webp", "heic", "avif"].includes(extension)
      ? extension
      : "jpg";
  const image = imageSchema.parse({
    file: `${randomUUID()}.${suffix}`,
    width: asset.width,
    height: asset.height,
  });
  new File(asset.uri).copy(new File(folder, image.file));
  return image;
}

export function pruneAttachments(referencedFiles: string[]) {
  const folder = directory();
  if (!folder.exists) return;
  const keep = new Set(referencedFiles);
  for (const file of folder.list()) {
    if (file instanceof File && !keep.has(file.name)) file.delete();
  }
}
