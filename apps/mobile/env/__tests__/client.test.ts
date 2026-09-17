import { afterEach, expect, test, vi } from "vitest";

vi.mock("expo-constants", () => ({
  default: {
    expoConfig: { extra: { useDevHost: true }, hostUri: "192.168.1.20:8081" },
  },
}));

afterEach(() => {
  vi.unstubAllGlobals();
  vi.unstubAllEnvs();
  vi.restoreAllMocks();
  vi.resetModules();
});

test("runtime entry reads public variables and emits development diagnostics", async () => {
  vi.stubGlobal("__DEV__", true);
  vi.stubEnv("EXPO_PUBLIC_API_BASE_URL", "https://env.example.com");
  vi.stubEnv("EXPO_PUBLIC_USE_DEV_HOST", "false");
  const log = vi.spyOn(console, "log").mockImplementation(() => {});
  const { config } = await import("../client");
  expect(config).toMatchObject({
    apiBaseUrl: "https://env.example.com",
    useDevHost: false,
    source: "env",
  });
  expect(log).toHaveBeenCalledWith(
    expect.stringContaining("EXPO_PUBLIC_API_BASE_URL"),
  );
});

test("runtime entry emits no configuration log in production", async () => {
  vi.stubGlobal("__DEV__", false);
  vi.stubEnv("EXPO_PUBLIC_API_BASE_URL", "https://api.example.com");
  vi.stubEnv("EXPO_PUBLIC_USE_DEV_HOST", "true");
  const log = vi.spyOn(console, "log").mockImplementation(() => {});
  const { config } = await import("../client");
  expect(config).toMatchObject({
    apiBaseUrl: "https://api.example.com",
    useDevHost: false,
  });
  expect(log).not.toHaveBeenCalled();
});
