import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["src/**/__tests__/**/*.test.ts"],
    setupFiles: ["./src/lib/test/setup.ts"],
    clearMocks: true,
    hookTimeout: 30_000,
  },
});
