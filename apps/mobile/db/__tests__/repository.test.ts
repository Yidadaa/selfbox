import { randomUUID } from "node:crypto";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, expect, test } from "vitest";
import { migrateDatabase } from "../migrate";
import { createPayload, editPayload } from "../payload";
import { createRepository, defaultChatId } from "../repository";
import { generatedMigrations, openTestDatabase } from "./sqlite";

const cleanups: (() => void)[] = [];
afterEach(() => {
  for (const cleanup of cleanups.splice(0).reverse()) cleanup();
});
async function setup(path?: string) {
  const { sqlite, adapter } = openTestDatabase(path);
  cleanups.push(() => sqlite.close());
  const db = await migrateDatabase(adapter, generatedMigrations);
  let time = 1_800_000_000_000;
  const repository = createRepository(db, randomUUID, () => ++time);
  return { repository, sqlite, adapter };
}
const text = (value: string) => ({
  version: 1 as const,
  type: "text" as const,
  text: value,
});

test("migrates once, preserves default chat and enforces foreign keys", async () => {
  const { repository, adapter, sqlite } = await setup();
  await migrateDatabase(adapter, generatedMigrations);
  expect(repository.listChats()).toHaveLength(1);
  expect(repository.getChat(defaultChatId)?.isDefault).toBe(true);
  expect(
    sqlite.prepare("SELECT COUNT(*) AS count FROM __drizzle_migrations").get()
      ?.count,
  ).toBe(generatedMigrations.journal.entries.length);
  expect(() => repository.send("missing", text("hello"))).toThrow();
  expect(repository.listMessages(defaultChatId)).toEqual([]);
});

test("creates chats, orders by latest message, edits, pins, unpins and deletes", async () => {
  const { repository } = await setup();
  const id = repository.createChat({
    name: "  Ideas  ",
    icon: { type: "lucide", name: "lightbulb" },
  });
  const first = repository.send(id, text("**hello**"));
  const second = repository.send(id, text("bot reply"), "bot");
  expect(repository.listMessages(id).map((message) => message.role)).toEqual([
    "bot",
    "user",
  ]);
  expect(repository.listChats()[0]).toMatchObject({
    id,
    name: "Ideas",
    latest: { id: second },
  });
  repository.edit(first, text("updated"));
  repository.togglePin(first);
  expect(repository.listPinned(id)).toMatchObject([
    { id: first, payload: text("updated") },
  ]);
  expect(repository.listMessages(id).map(({ id }) => id)).toEqual([
    second,
    first,
  ]);
  repository.togglePin(first);
  expect(repository.listPinned(id)).toEqual([]);
  repository.deleteMessage(second);
  expect(repository.listChats()[0]?.latest?.id).toBe(first);
  repository.deleteMessage(first);
  expect(repository.listChats()[0]?.latest).toBeNull();
  expect(() => repository.edit("missing", text("no"))).toThrow();
});

test("keeps image payload, bot role and pins across database reopen", async () => {
  const folder = mkdtempSync(join(tmpdir(), "selfbox-test-"));
  cleanups.push(() => rmSync(folder, { recursive: true, force: true }));
  const path = join(folder, "selfbox.db");
  const { repository } = await setup(path);
  const payload = {
    version: 1 as const,
    type: "image" as const,
    image: { file: "photo-1.jpg", width: 800, height: 600 },
    caption: "**a memory**",
  };
  const id = repository.send(defaultChatId, payload, "bot");
  repository.togglePin(id);
  // 先关闭，再建立新连接，确保没有复用内存数据。
  cleanups.pop()?.();
  const next = (await setup(path)).repository;
  expect(next.listMessages(defaultChatId)).toMatchObject([
    { id, role: "bot", payload },
  ]);
  expect(next.listPinned(defaultChatId)[0]?.id).toBe(id);
  expect(next.imageFiles()).toEqual(["photo-1.jpg"]);
});

test("clears messages and chats atomically and recreates one empty monologue", async () => {
  const { repository } = await setup();
  const id = repository.createChat({
    name: "notes",
    icon: { type: "emoji", value: "🌱" },
  });
  repository.send(defaultChatId, text("private"));
  repository.send(id, text("also private"));
  repository.clear();
  repository.clear();
  expect(repository.listChats()).toMatchObject([
    { id: defaultChatId, latest: null },
  ]);
  expect(repository.listMessages(id)).toEqual([]);
  expect(repository.imageFiles()).toEqual([]);
});

test("persists albums, edits individual photos and tracks all referenced files", async () => {
  const folder = mkdtempSync(join(tmpdir(), "selfbox-album-"));
  cleanups.push(() => rmSync(folder, { recursive: true, force: true }));
  const path = join(folder, "selfbox.db");
  const { repository } = await setup(path);
  const images = [
    { file: "first.jpg", width: 800, height: 600 },
    { file: "second.jpg", width: 600, height: 800 },
    { file: "third.png", width: 600, height: 600 },
  ];
  const album = createPayload("album", images);
  const id = repository.send(defaultChatId, album);
  const legacy = repository.send(
    defaultChatId,
    createPayload("", images.slice(0, 1)),
  );
  cleanups.pop()?.();
  const next = (await setup(path)).repository;
  expect(
    next.listMessages(defaultChatId).find((message) => message.id === id)
      ?.payload,
  ).toEqual(album);
  expect(next.imageFiles().sort()).toEqual([
    "first.jpg",
    "first.jpg",
    "second.jpg",
    "third.png",
  ]);
  next.edit(id, editPayload(album, "edited"));
  next.togglePin(id);
  expect(next.listPinned(defaultChatId)[0]?.payload).toEqual({
    ...album,
    caption: "edited",
  });
  next.edit(id, createPayload("", images.slice(1)));
  expect(next.listChats()[0]?.latest?.id).toBe(legacy);
  next.deleteMessage(legacy);
  expect(next.listChats()[0]?.latest?.payload).toEqual(
    createPayload("", images.slice(1)),
  );
  expect(next.imageFiles().sort()).toEqual(["second.jpg", "third.png"]);
  next.edit(id, createPayload("caption only", []));
  expect(next.imageFiles()).toEqual([]);
  next.deleteMessage(id);
  expect(next.listMessages(defaultChatId)).toEqual([]);
});

test("rejects invalid data before writing", async () => {
  const { repository, sqlite } = await setup();
  expect(() =>
    repository.createChat({
      name: " ",
      icon: { type: "lucide", name: "missing" },
    }),
  ).toThrow();
  expect(() => repository.send(defaultChatId, text("  "))).toThrow();
  expect(repository.listMessages(defaultChatId)).toEqual([]);
  expect(() =>
    sqlite
      .prepare("INSERT INTO messages VALUES (?, ?, ?, ?, NULL, 1, 1)")
      .run("bad", defaultChatId, "invalid", "{}"),
  ).toThrow();
});

test("rolls back deletion if rebuilding the default chat fails", async () => {
  const { repository, sqlite } = await setup();
  repository.send(defaultChatId, text("keep me"));
  sqlite.exec(
    "CREATE TRIGGER block_default BEFORE INSERT ON chats BEGIN SELECT RAISE(ABORT, 'test'); END",
  );
  expect(() => repository.clear()).toThrow();
  expect(repository.listMessages(defaultChatId)[0]?.payload).toEqual(
    text("keep me"),
  );
});

test("rejects missing migration files and rolls back failed schema upgrades", async () => {
  const { repository, sqlite, adapter } = await setup();
  repository.send(defaultChatId, text("keep through upgrade"));
  const idx = generatedMigrations.journal.entries.length;
  const journal = {
    entries: [
      ...generatedMigrations.journal.entries,
      { idx, when: Date.now() + 100_000, tag: "upgrade", breakpoints: true },
    ],
  };
  await expect(
    migrateDatabase(adapter, { ...generatedMigrations, journal }),
  ).rejects.toThrow("Missing migration");
  await expect(
    migrateDatabase(adapter, {
      journal,
      migrations: {
        ...generatedMigrations.migrations,
        [`m${String(idx).padStart(4, "0")}`]:
          "CREATE TABLE upgrade_probe (id INTEGER);--> statement-breakpoint INSERT INTO missing_table VALUES (1);",
      },
    }),
  ).rejects.toThrow();
  expect(
    sqlite
      .prepare("SELECT name FROM sqlite_master WHERE name = 'upgrade_probe'")
      .get(),
  ).toBeUndefined();
  expect(
    sqlite.prepare("SELECT COUNT(*) AS count FROM __drizzle_migrations").get()
      ?.count,
  ).toBe(idx);
  expect(repository.listMessages(defaultChatId)[0]?.payload).toEqual(
    text("keep through upgrade"),
  );
});
