import { expect, test } from "vitest";
import {
  chatInputSchema,
  createPayload,
  editPayload,
  messageImages,
  messageText,
  payloadSchema,
  roleSchema,
} from "../payload";

test("validates discriminated versioned payloads and reserves bot role", () => {
  expect(
    payloadSchema.parse({ version: 1, type: "text", text: " **hello** " }),
  ).toEqual({ version: 1, type: "text", text: "**hello**" });
  expect(roleSchema.parse("bot")).toBe("bot");
  for (const payload of [
    { version: 2, type: "text", text: "hi" },
    { version: 1, type: "audio" },
    { version: 1, type: "text", text: " " },
    {
      version: 1,
      type: "image",
      image: { file: "../photo.jpg", width: 1, height: 1 },
    },
  ]) {
    expect(payloadSchema.safeParse(payload).success).toBe(false);
  }
});

test("creates text, single photos and ordered albums and preserves captions", () => {
  const images = [
    { file: "first.jpg", width: 800, height: 600 },
    { file: "second.png", width: 600, height: 800 },
  ];
  expect(createPayload(" note ", [])).toEqual({
    version: 1,
    type: "text",
    text: "note",
  });
  const single = createPayload("", images.slice(0, 1));
  expect(single.type).toBe("image");
  expect(messageImages(single)).toEqual(images.slice(0, 1));
  const album = createPayload(" caption ", images);
  expect(album).toEqual({
    version: 1,
    type: "images",
    images,
    caption: "caption",
  });
  expect(messageImages(album)).toEqual(images);
  expect(messageImages(createPayload("text", []))).toEqual([]);
  expect(editPayload(album, "edited")).toEqual({ ...album, caption: "edited" });
  expect(messageText(album)).toBe("caption");
  expect(() => createPayload(" ", [])).toThrow();
  expect(
    payloadSchema.safeParse({ version: 1, type: "images", images: [] }).success,
  ).toBe(false);
  expect(
    payloadSchema.safeParse({
      version: 1,
      type: "images",
      images: [{ ...images[0], file: "../private.jpg" }],
    }).success,
  ).toBe(false);
});

test("edits text and image captions without losing attachments", () => {
  const image = payloadSchema.parse({
    version: 1,
    type: "image",
    image: { file: "memory.png", width: 100, height: 80 },
  });
  expect(messageText(image)).toBe("");
  expect(editPayload(image, "caption")).toEqual({
    ...image,
    caption: "caption",
  });
  expect(
    messageText(
      editPayload({ version: 1, type: "text", text: "first" }, "second"),
    ),
  ).toBe("second");
});

test("accepts one composed emoji or Lucide name and rejects arbitrary icon text", () => {
  for (const value of ["🌱", "👩🏽‍💻", "🇨🇳", "1️⃣", "❤️"])
    expect(
      chatInputSchema.safeParse({
        name: "Journal",
        icon: { type: "emoji", value },
      }).success,
    ).toBe(true);
  for (const value of ["hello", "🌱🌱", "", "1"])
    expect(
      chatInputSchema.safeParse({
        name: "Journal",
        icon: { type: "emoji", value },
      }).success,
    ).toBe(false);
  expect(
    chatInputSchema.safeParse({
      name: "Journal",
      icon: { type: "lucide", name: "notebook" },
    }).success,
  ).toBe(true);
});
