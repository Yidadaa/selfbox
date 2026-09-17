import type { ImageAttachment } from "@/db/payload";

export function imageRows(images: ImageAttachment[]): ImageAttachment[][] {
  if (images.length === 0) return [];
  if (images.length === 3) return [images.slice(0, 1), images.slice(1)];
  const rows: ImageAttachment[][] = [];
  const rowCount = Math.ceil(images.length / (images.length <= 4 ? 2 : 3));
  let offset = 0;
  for (let row = 0; row < rowCount; row++) {
    const count = Math.ceil((images.length - offset) / (rowCount - row));
    rows.push(images.slice(offset, offset + count));
    offset += count;
  }
  return rows;
}
