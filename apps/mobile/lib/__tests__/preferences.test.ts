import { expect, test } from "vitest";
import { createPreferencesStore } from "../preferences";

test("persists and restores theme, language and chat style", async () => {
  const saved = new Map<string, string>();
  const storage = {
    getItem: (key: string) => saved.get(key) ?? null,
    setItem: (key: string, value: string) => {
      saved.set(key, value);
    },
    removeItem: (key: string) => {
      saved.delete(key);
    },
  };
  const first = createPreferencesStore(storage);
  await first.persist.rehydrate();
  first
    .getState()
    .update({ theme: "dark", language: "zh", chatStyle: "green" });
  const second = createPreferencesStore(storage);
  await second.persist.rehydrate();
  expect(second.getState()).toMatchObject({
    theme: "dark",
    language: "zh",
    chatStyle: "green",
  });
});

test("uses safe defaults for invalid stored preferences", async () => {
  const store = createPreferencesStore({
    getItem: () =>
      JSON.stringify({
        state: { theme: "unknown", language: 123, chatStyle: null },
        version: 0,
      }),
    setItem: () => {},
    removeItem: () => {},
  });
  await store.persist.rehydrate();
  expect(store.getState()).toMatchObject({
    theme: "system",
    language: "system",
    chatStyle: "blue",
  });
});
