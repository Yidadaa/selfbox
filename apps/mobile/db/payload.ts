import { z } from "zod";

export const iconNames = [
  "message",
  "notebook",
  "lightbulb",
  "heart",
  "star",
  "bookmark",
  "coffee",
  "moon",
  "leaf",
  "camera",
  "music",
  "globe",
] as const;
export const chatIconSchema = z.discriminatedUnion("type", [
  z.object({ type: z.literal("lucide"), name: z.enum(iconNames) }),
  z.object({
    type: z.literal("emoji"),
    value: z
      .string()
      .trim()
      .max(32)
      .regex(
        /^(?:\p{Regional_Indicator}{2}|[0-9#*]\uFE0F?\u20E3|\p{Extended_Pictographic}\uFE0F?\p{Emoji_Modifier}?(?:\u200D\p{Extended_Pictographic}\uFE0F?\p{Emoji_Modifier}?)*)$/u,
      ),
  }),
]);
export const chatInputSchema = z.object({
  name: z.string().trim().min(1).max(60),
  icon: chatIconSchema,
});
export const imageSchema = z.object({
  // 保存相对文件名；iOS 应用容器的绝对路径可能在更新后改变。
  file: z.string().regex(/^[a-zA-Z0-9-]+\.(jpg|jpeg|png|webp|heic|avif)$/),
  width: z.number().positive(),
  height: z.number().positive(),
});
export const payloadSchema = z.discriminatedUnion("type", [
  z.object({
    version: z.literal(1),
    type: z.literal("text"),
    text: z.string().trim().min(1).max(50_000),
  }),
  z.object({
    version: z.literal(1),
    type: z.literal("image"),
    image: imageSchema,
    caption: z.string().trim().max(50_000).default(""),
  }),
  z.object({
    version: z.literal(1),
    type: z.literal("images"),
    images: z.array(imageSchema).min(1),
    caption: z.string().trim().max(50_000).default(""),
  }),
]);
export const roleSchema = z.enum(["user", "bot"]);
export type ChatIcon = z.infer<typeof chatIconSchema>;
export type Payload = z.infer<typeof payloadSchema>;
export type ImageAttachment = z.infer<typeof imageSchema>;
export type Role = z.infer<typeof roleSchema>;

export function messageImages(payload: Payload): ImageAttachment[] {
  if (payload.type === "text") return [];
  return payload.type === "image" ? [payload.image] : payload.images;
}

export function createPayload(
  text: string,
  images: ImageAttachment[],
): Payload {
  return payloadSchema.parse(
    images.length === 0
      ? { version: 1, type: "text", text }
      : images.length === 1
        ? { version: 1, type: "image", image: images[0], caption: text }
        : { version: 1, type: "images", images, caption: text },
  );
}

export function messageText(payload: Payload) {
  return payload.type === "text" ? payload.text : payload.caption;
}

export function editPayload(payload: Payload, text: string): Payload {
  return payloadSchema.parse(
    payload.type === "text"
      ? { ...payload, text }
      : { ...payload, caption: text },
  );
}
