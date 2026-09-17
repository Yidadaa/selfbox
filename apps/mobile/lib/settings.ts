import {
  createJSONStorage,
  persist,
  type StateStorage,
} from "zustand/middleware";
import { createStore } from "zustand/vanilla";
import { normalizeHost } from "./config";

interface Settings {
  devHost: string | null;
  setDevHost: (value: string) => void;
  reset: () => void;
}

export function createSettingsStore(storage: StateStorage) {
  return createStore<Settings>()(
    persist(
      (set) => ({
        devHost: null,
        setDevHost: (value) => set({ devHost: normalizeHost(value) }),
        reset: () => set({ devHost: null }),
      }),
      {
        name: "expo-starter.dev-settings",
        version: 1,
        storage: createJSONStorage(() => storage),
        partialize: ({ devHost }) => ({ devHost }),
        skipHydration: true,
        merge: (persisted, current) => {
          try {
            const value = (persisted as { devHost?: unknown } | undefined)
              ?.devHost;
            return {
              ...current,
              devHost: typeof value === "string" ? normalizeHost(value) : null,
            };
          } catch {
            return current;
          }
        },
      },
    ),
  );
}
