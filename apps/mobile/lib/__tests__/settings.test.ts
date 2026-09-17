import { expect, test } from "vitest";
import { createSettingsStore } from "../settings";

function memoryStorage() {
  const values = new Map<string, string>();
  return {
    values,
    getItem: async (key: string) => values.get(key) ?? null,
    setItem: async (key: string, value: string) => {
      values.set(key, value);
    },
    removeItem: async (key: string) => {
      values.delete(key);
    },
  };
}

test("persists dev host, restores on launch, and resets to configured host", async () => {
  const storage = memoryStorage();
  const first = createSettingsStore(storage);
  await first.persist.rehydrate();
  first.getState().setDevHost("http://192.168.1.20:3000/");
  const second = createSettingsStore(storage);
  expect(second.persist.hasHydrated()).toBe(false);
  await second.persist.rehydrate();
  expect(second.getState().devHost).toBe("http://192.168.1.20:3000");
  expect(JSON.parse(storage.values.get("selfbox.dev-settings") ?? "")).toEqual({
    state: { devHost: "http://192.168.1.20:3000" },
    version: 1,
  });
  second.getState().reset();
  await first.persist.rehydrate();
  expect(first.getState().devHost).toBeNull();
});

test("discards malformed persisted hosts and rejects invalid edits", async () => {
  const storage = memoryStorage();
  storage.values.set(
    "selfbox.dev-settings",
    JSON.stringify({ state: { devHost: "file:///private" }, version: 1 }),
  );
  const store = createSettingsStore(storage);
  await store.persist.rehydrate();
  expect(store.getState().devHost).toBeNull();
  expect(() =>
    store.getState().setDevHost("https://example.com/api"),
  ).toThrow();
});

test("failed storage hydration leaves usable defaults", async () => {
  const store = createSettingsStore({
    ...memoryStorage(),
    getItem: async () => {
      throw new Error("storage unavailable");
    },
  });
  await store.persist.rehydrate();
  expect(store.persist.hasHydrated()).toBe(false);
  expect(store.getState().devHost).toBeNull();
});
