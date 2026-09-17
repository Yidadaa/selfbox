import { afterEach, expect, test, vi } from "vitest";

const secureValues = vi.hoisted(() => new Map<string, string>());
vi.mock("expo-secure-store", () => ({
  getItem: (key: string) => secureValues.get(key) ?? null,
  setItem: (key: string, value: string) => {
    secureValues.set(key, value);
  },
  getItemAsync: async (key: string) => secureValues.get(key) ?? null,
  setItemAsync: async (key: string, value: string) => {
    secureValues.set(key, value);
  },
  deleteItemAsync: async (key: string) => {
    secureValues.delete(key);
  },
}));
vi.mock("expo-constants", () => ({
  default: { expoConfig: { scheme: "selfbox" } },
}));
vi.mock("expo-linking", () => ({ createURL: () => "selfbox://" }));
vi.mock("react-native", () => ({
  Platform: { OS: "ios" },
  AppState: { addEventListener: () => ({ remove() {} }) },
}));
vi.mock("expo-network", () => ({
  addNetworkStateListener: () => ({ remove() {} }),
}));

import { createMobileAuth } from "../auth";

afterEach(() => {
  vi.unstubAllGlobals();
  secureValues.clear();
});

test("Expo auth stores cookies securely, restores them, isolates hosts, and clears on logout", async () => {
  const requests: {
    url: string;
    headers: Headers;
    credentials?: RequestCredentials;
  }[] = [];
  vi.stubGlobal(
    "fetch",
    vi.fn(async (input: string | URL, init: RequestInit) => {
      const url = String(input);
      requests.push({
        url,
        headers: new Headers(init.headers),
        credentials: init.credentials,
      });
      if (url.endsWith("/sign-in/email"))
        return Response.json(
          { user: { id: "alice" }, token: "test-token" },
          {
            headers: {
              "set-cookie":
                "better-auth.session_token=test-token; Path=/; HttpOnly; Max-Age=3600",
            },
          },
        );
      return Response.json({ success: true });
    }),
  );
  const first = createMobileAuth("http://localhost:3000");
  const result = await first.signIn.email({
    email: "alice@example.com",
    password: "test-password",
  });
  expect(result.error).toBeNull();
  expect(requests[0]?.url).toBe("http://localhost:3000/api/auth/sign-in/email");
  expect(requests[0]?.headers.get("expo-origin")).toBe("selfbox://");
  expect(requests[0]?.credentials).toBe("omit");
  expect(await first.getCookie()).toContain(
    "better-auth.session_token=test-token",
  );
  const restored = createMobileAuth("http://localhost:3000");
  expect(await restored.getCookie()).toBe(await first.getCookie());
  expect(await createMobileAuth("http://localhost:3001").getCookie()).toBe("");
  await restored.signOut();
  expect(await restored.getCookie()).toBe("");
});
