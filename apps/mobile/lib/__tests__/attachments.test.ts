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
  appendPhotos,
  attachmentUri,
  importAttachment,
  photoUri,
  pruneAttachments,
  savePhotos,
} from "../attachments";

test("appends multiple selections in order and skips repeated assets or URIs", () => {
  const first = {
    uri: "file:///cache/one.jpg",
    width: 800,
    height: 600,
    assetId: "one",
  };
  const second = { uri: "file:///cache/two.jpg", width: 800, height: 600 };
  const third = {
    uri: "file:///cache/three.jpg",
    width: 800,
    height: 600,
    assetId: "three",
  };
  expect(
    appendPhotos(
      [first],
      [{ ...first, uri: "file:///cache/one-again.jpg" }, second, second, third],
    ),
  ).toEqual([first, second, third]);
  expect(appendPhotos([first], [])).toEqual([first]);
  expect(appendPhotos([], [first, second])).toEqual([first, second]);
});

beforeEach(() => {
  state.files.clear();
  state.sequence = 0;
  state.document = "file:///container-a/documents";
});

test("saves mixed existing and picked photos in order without copying existing attachments", () => {
  const existing = { file: "existing.jpg", width: 800, height: 600 };
  const picked = {
    uri: "file:///cache/new.png",
    width: 600,
    height: 800,
    mimeType: "image/png",
  };
  state.files.set(attachmentUri(existing), "existing bytes");
  state.files.set(picked.uri, "new bytes");
  expect(photoUri(existing)).toBe(attachmentUri(existing));
  expect(photoUri(picked)).toBe(picked.uri);
  expect(savePhotos(" album ", [existing, picked])).toEqual({
    version: 1,
    type: "images",
    images: [existing, { file: "photo-1.png", width: 600, height: 800 }],
    caption: "album",
  });
  expect(state.sequence).toBe(1);
  pruneAttachments([existing.file, "photo-1.png"]);
  expect(state.files.get(attachmentUri(existing))).toBe("existing bytes");
  expect(
    state.files.get(
      attachmentUri({ file: "photo-1.png", width: 600, height: 800 }),
    ),
  ).toBe("new bytes");
  expect(savePhotos("caption only", [])).toEqual({
    version: 1,
    type: "text",
    text: "caption only",
  });
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
