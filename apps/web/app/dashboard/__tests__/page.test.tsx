import { beforeEach, expect, test, vi } from "vitest";
import { AuthClient, DashboardClient } from "../client";
import DashboardPage from "../page";

const { getSession, requestHeaders } = vi.hoisted(() => ({
  getSession: vi.fn(),
  requestHeaders: new Headers({ cookie: "better-auth.session_token=test" }),
}));

vi.mock("next/headers", () => ({ headers: async () => requestHeaders }));
vi.mock("@/lib/server", () => ({
  getServices: () => ({ auth: { api: { getSession } } }),
}));
vi.mock("../client", () => ({
  AuthClient: () => null,
  DashboardClient: () => null,
}));

beforeEach(() => {
  getSession.mockReset();
});

test("anonymous or expired sessions only receive the public auth entry", async () => {
  getSession.mockResolvedValue(null);
  const page = await DashboardPage();
  expect(page.type).toBe(AuthClient);
  expect(getSession).toHaveBeenCalledWith({
    headers: requestHeaders,
    query: { disableCookieCache: true },
  });
});

test("a validated session can load the dashboard without serializing the session", async () => {
  getSession.mockResolvedValue({
    user: { id: "user-1" },
    session: { token: "private-token" },
  });
  const page = await DashboardPage();
  expect(page.type).toBe(DashboardClient);
  expect(page.props).toEqual({});
});

test("auth service failure never falls through to the dashboard", async () => {
  getSession.mockRejectedValue(new Error("Session service unavailable"));
  await expect(DashboardPage()).rejects.toThrow("Session service unavailable");
});
