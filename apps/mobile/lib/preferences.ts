import { z } from "zod";
import {
  createJSONStorage,
  persist,
  type StateStorage,
} from "zustand/middleware";
import { createStore } from "zustand/vanilla";

export const preferencesSchema = z.object({
  theme: z.enum(["system", "light", "dark"]).catch("system"),
  language: z.enum(["system", "zh", "en"]).catch("system"),
  chatStyle: z.enum(["blue", "green", "mono"]).catch("blue"),
});
export type Preferences = z.infer<typeof preferencesSchema>;

export function createPreferencesStore(storage: StateStorage) {
  return createStore<
    Preferences & {
      update: (value: Partial<Preferences>) => void;
    }
  >()(
    persist(
      (set) => ({
        ...preferencesSchema.parse({}),
        update: (value) => set(value),
      }),
      {
        name: "selfbox.preferences",
        storage: createJSONStorage(() => storage),
        skipHydration: true,
        partialize: ({ theme, language, chatStyle }) => ({
          theme,
          language,
          chatStyle,
        }),
        merge: (saved, current) => ({
          ...current,
          ...preferencesSchema.parse(saved ?? {}),
        }),
      },
    ),
  );
}
