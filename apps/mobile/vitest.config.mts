import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
  resolve: { alias: { "@": fileURLToPath(new URL(".", import.meta.url)) } },
  test: {
    server: { deps: { inline: [/@better-auth\/expo/] } },
    environment: "node",
    include: ["**/__tests__/**/*.test.ts"],
    clearMocks: true,
  },
});
