import { beforeEach, expect, test, vi } from "vitest";

const state = vi.hoisted(() => ({
  files: new Map<string, string>(),
  document: "file:///container-a/documents",
  sequence: 0,
}));
vi.mock("expo-crypto", () => ({
  randomUUID: () => `photo-${++state.sequence}`,
}));
vi.mock("expo-file-system", () => {
  class Directory {
    uri: string;
    constructor(...parts: (string | { uri: string })[]) {
      this.uri = parts
        .map((part) => (typeof part === "string" ? part : part.uri))
        .join("/");
    }
    create() {}
    get exists() {
      return true;
    }
    list() {
      return [...state.files.keys()]
        .filter((path) => path.startsWith(`${this.uri}/`))
        .map((path) => new File(path));
    }
  }
  class File {
    uri: string;
    constructor(...parts: (string | { uri: string })[]) {
      this.uri = parts
        .map((part) => (typeof part === "string" ? part : part.uri))
        .join("/");
    }
    get name() {
      return this.uri.split("/").at(-1);
    }
    copy(target: File) {
      const content = state.files.get(this.uri);
      if (content === undefined) throw new Error("Missing photo");
      state.files.set(target.uri, content);
    }
    delete() {
      state.files.delete(this.uri);
    }
  }
  return {
    Directory,
    File,
    Paths: {
      get document() {
        return state.document;
      },
    },
  };
});

import {
  attachmentUri,
  importAttachment,
  pruneAttachments,
} from "../attachments";

beforeEach(() => {
  state.files.clear();
  state.sequence = 0;
  state.document = "file:///container-a/documents";
});

test("copies picked photos out of cache, keeps referenced files and prunes orphans", () => {
  state.files.set("file:///cache/picked.png", "photo bytes");
  const image = importAttachment({
    uri: "file:///cache/picked.png",
    width: 800,
    height: 600,
    mimeType: "image/png",
  });
  const orphan = importAttachment({
    uri: "file:///cache/picked.png",
    width: 800,
    height: 600,
  });
  state.files.delete("file:///cache/picked.png");
  expect(state.files.get(attachmentUri(image))).toBe("photo bytes");
  expect(image).toMatchObject({ file: "photo-1.png", width: 800, height: 600 });
  pruneAttachments([image.file]);
  expect(state.files.has(attachmentUri(image))).toBe(true);
  expect(state.files.has(attachmentUri(orphan))).toBe(false);
  pruneAttachments([]);
  expect(state.files.size).toBe(0);
});

test("resolves relative filenames against the current app container and rejects traversal", () => {
  state.document = "file:///container-b/documents";
  expect(attachmentUri({ file: "photo.jpg", width: 1, height: 1 })).toBe(
    "file:///container-b/documents/attachments/photo.jpg",
  );
  expect(() =>
    attachmentUri({ file: "../private.jpg", width: 1, height: 1 }),
  ).toThrow();
  expect(() =>
    importAttachment({ uri: "file:///missing", width: 1, height: 1 }),
  ).toThrow("Missing photo");
});
