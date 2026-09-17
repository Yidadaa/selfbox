import { expect, test } from "vitest";
import {
  chatInputSchema,
  editPayload,
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
