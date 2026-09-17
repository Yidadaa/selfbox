import { describe, expect, test } from "vitest";
import { createMobileEnv } from "../../env";
import {
  formatConfigLog,
  loadConfig,
  loadDevHost,
  normalizeHost,
  resolveHost,
  sessionStoragePrefix,
} from "../config";

describe("server configuration", () => {
  test("normalizes LAN addresses and uses explicit BASE_URL before Vercel", () => {
    expect(normalizeHost(" http://192.168.1.20:3000/ ")).toBe(
      "http://192.168.1.20:3000",
    );
    expect(
      createMobileEnv({
        BASE_URL: "https://api.example.com",
        VERCEL_URL: "preview.example.com",
      }).BASE_URL,
    ).toBe("https://api.example.com");
    expect(
      createMobileEnv({ VERCEL_URL: "preview.example.com" }).BASE_URL,
    ).toBe("https://preview.example.com");
    expect(createMobileEnv({}).BASE_URL).toBeUndefined();
  });
  test.each([
    "localhost:3000",
    "file:///tmp",
    "https://user:pass@example.com",
    "https://example.com/api",
    "https://example.com?token=a",
    "https://example.com#home",
  ])("rejects invalid origin %s", (value) => {
    expect(() => normalizeHost(value)).toThrow();
  });
  test("ignores persisted development overrides in release builds", () => {
    expect(
      resolveHost("https://api.example.com", "http://localhost:3000", true),
    ).toBe("http://localhost:3000");
    expect(
      resolveHost("https://api.example.com", "http://localhost:3000", false),
    ).toBe("https://api.example.com");
    expect(resolveHost(null, null, true)).toBeNull();
    expect(resolveHost("invalid", null, false)).toBeNull();
  });
  test("isolates secure storage by normalized origin", () => {
    expect(sessionStoragePrefix("http://localhost:3000/")).toBe(
      sessionStoragePrefix("http://localhost:3000"),
    );
    expect(sessionStoragePrefix("http://localhost:3000")).not.toBe(
      sessionStoragePrefix("http://localhost:3001"),
    );
    expect(sessionStoragePrefix("http://localhost:3000")).not.toBe(
      sessionStoragePrefix("https://localhost:3000"),
    );
    expect(sessionStoragePrefix("http://[::1]:3000")).toMatch(
      /^[a-zA-Z0-9._-]+$/,
    );
  });
});

describe("Expo development environment", () => {
  test.each([
    ["192.168.1.20:8081", "http://192.168.1.20:3000"],
    ["exp://192.168.1.20:8081/--/login", "http://192.168.1.20:3000"],
    ["http://localhost:8081", "http://localhost:3000"],
    ["[::1]:8081", "http://[::1]:3000"],
    ["http://[2001:db8::1]:8081", "http://[2001:db8::1]:3000"],
  ])("derives API origin from %s", (hostUri, expected) => {
    expect(loadDevHost(hostUri).apiBaseUrl).toBe(expected);
  });

  test.each([
    undefined,
    "",
    "not a host",
    "file:///tmp",
    "http://user:pass@localhost:8081",
  ])("rejects unusable Metro host %s", (hostUri) => {
    expect(() => loadDevHost(hostUri)).toThrow("Cannot derive the API host");
  });

  test("public environment values override extra while missing fields preserve extra", () => {
    const config = loadConfig({
      expoExtra: { apiBaseUrl: "https://extra.example.com/", useDevHost: true },
      publicEnv: {
        EXPO_PUBLIC_USE_DEV_HOST: "false",
        EXPO_PUBLIC_API_BASE_URL: "https://env.example.com/",
      },
      hostUri: "192.168.1.20:8081",
      isDev: true,
    });
    expect(config).toMatchObject({
      apiBaseUrl: "https://env.example.com",
      useDevHost: false,
      source: "env",
    });
    expect(
      loadConfig({
        expoExtra: {
          apiBaseUrl: "https://extra.example.com",
          useDevHost: true,
        },
        publicEnv: {
          EXPO_PUBLIC_API_BASE_URL: undefined,
          EXPO_PUBLIC_USE_DEV_HOST: "",
        },
        hostUri: "192.168.1.20:8081",
        isDev: true,
      }),
    ).toMatchObject({
      apiBaseUrl: "http://192.168.1.20:3000",
      useDevHost: true,
      source: "devHost",
    });
  });

  test.each([
    ["true", true],
    ["1", true],
    ["false", false],
    ["0", false],
    [true, true],
    [false, false],
  ] as const)("parses boolean %s explicitly", (value, expected) => {
    const config = loadConfig({
      publicEnv: { EXPO_PUBLIC_USE_DEV_HOST: value },
      hostUri: "localhost:8081",
      isDev: true,
    });
    expect(config.useDevHost).toBe(expected);
  });

  test("automatic host overrides configured URL and /dev overrides both", () => {
    const config = loadConfig({
      publicEnv: {
        EXPO_PUBLIC_API_BASE_URL: "https://api.example.com",
        EXPO_PUBLIC_USE_DEV_HOST: "true",
      },
      hostUri: "192.168.1.20:8081",
      isDev: true,
    });
    expect(config.apiBaseUrl).toBe("http://192.168.1.20:3000");
    expect(
      resolveHost(config.apiBaseUrl, "http://192.168.1.30:4000", true),
    ).toBe("http://192.168.1.30:4000");
  });

  test("production ignores automatic and persisted hosts", () => {
    const config = loadConfig({
      publicEnv: {
        EXPO_PUBLIC_API_BASE_URL: "https://api.example.com",
        EXPO_PUBLIC_USE_DEV_HOST: "true",
      },
      hostUri: null,
      isDev: false,
    });
    expect(config).toMatchObject({
      apiBaseUrl: "https://api.example.com",
      useDevHost: false,
      source: "env",
      devHostError: null,
    });
    expect(resolveHost(config.apiBaseUrl, "http://localhost:3000", false)).toBe(
      "https://api.example.com",
    );
  });

  test("missing hostUri preserves explicit fallback and does not prevent manual configuration", () => {
    const config = loadConfig({
      expoExtra: { apiBaseUrl: "https://api.example.com", useDevHost: true },
      isDev: true,
    });
    expect(config).toMatchObject({
      apiBaseUrl: "https://api.example.com",
      source: "expo",
      devHostError: expect.stringContaining("/dev"),
    });
    const missing = loadConfig({
      expoExtra: { useDevHost: true },
      isDev: true,
    });
    expect(missing.apiBaseUrl).toBeUndefined();
    expect(resolveHost(missing.apiBaseUrl, "http://localhost:3000", true)).toBe(
      "http://localhost:3000",
    );
  });

  test("invalid configuration reports source and field instead of silently falling back", () => {
    expect(() =>
      loadConfig({
        publicEnv: { EXPO_PUBLIC_USE_DEV_HOST: "maybe" },
        isDev: true,
      }),
    ).toThrow(/环境变量[\s\S]*EXPO_PUBLIC_USE_DEV_HOST/);
    expect(() =>
      loadConfig({ expoExtra: { apiBaseUrl: "file:///tmp" }, isDev: true }),
    ).toThrow(/Expo extra[\s\S]*apiBaseUrl/);
  });

  test("diagnostics describe defined sources and log only allowlisted public settings", () => {
    const config = loadConfig({
      expoExtra: {
        apiBaseUrl: "https://api.example.com",
        secret: "must-not-log",
      },
      publicEnv: { EXPO_PUBLIC_USE_DEV_HOST: "false", SECRET: "must-not-log" },
      isDev: true,
    });
    expect(config.rows).toEqual([
      {
        name: "apiBaseUrl",
        env: "EXPO_PUBLIC_API_BASE_URL",
        expo: true,
        environment: false,
        value: "https://api.example.com",
      },
      {
        name: "useDevHost",
        env: "EXPO_PUBLIC_USE_DEV_HOST",
        expo: false,
        environment: true,
        value: false,
      },
    ]);
    expect(formatConfigLog(config)).toContain("API source: expo");
    expect(formatConfigLog(config)).not.toContain("must-not-log");
  });

  test("build environment uses the same boolean and URL validation", () => {
    expect(
      createMobileEnv({
        EXPO_PUBLIC_USE_DEV_HOST: "false",
        EXPO_PUBLIC_API_BASE_URL: "https://api.example.com/",
      }),
    ).toMatchObject({
      EXPO_PUBLIC_USE_DEV_HOST: false,
      EXPO_PUBLIC_API_BASE_URL: "https://api.example.com",
    });
  });
});
