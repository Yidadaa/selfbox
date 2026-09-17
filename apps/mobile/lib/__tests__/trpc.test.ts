import superjson from "superjson";
import { afterEach, expect, test, vi } from "vitest";
import { createMobileTRPC } from "../trpc";

afterEach(() => {
  vi.unstubAllGlobals();
  vi.useRealTimers();
});

test("tRPC sends the current session cookie and decodes SuperJSON", async () => {
  const mockFetch = vi.fn(async () =>
    Response.json([
      { result: { data: superjson.serialize({ id: "alice", name: "Alice" }) } },
    ]),
  );
  vi.stubGlobal("fetch", mockFetch);
  let cookie = "better-auth.session_token=alice";
  const client = createMobileTRPC("http://localhost:3000/", () => cookie);
  expect(await client.user.me.query()).toEqual({ id: "alice", name: "Alice" });
  expect(mockFetch).toHaveBeenLastCalledWith(
    expect.stringContaining("http://localhost:3000/api/trpc/user.me"),
    expect.objectContaining({
      credentials: "omit",
      headers: expect.objectContaining({ Cookie: cookie }),
    }),
  );
  cookie = "";
  await client.health.query();
  expect(mockFetch).toHaveBeenLastCalledWith(
    expect.anything(),
    expect.objectContaining({
      headers: expect.not.objectContaining({ Cookie: expect.anything() }),
    }),
  );
});

test("connection checks time out instead of waiting indefinitely", async () => {
  vi.useFakeTimers();
  vi.stubGlobal(
    "fetch",
    vi.fn(
      (_url: string, init: RequestInit) =>
        new Promise((_resolve, reject) => {
          init.signal?.addEventListener("abort", () =>
            reject(new Error("aborted")),
          );
        }),
    ),
  );
  const request = createMobileTRPC("http://localhost:3000").health.query();
  const rejection = expect(request).rejects.toThrow("aborted");
  await vi.advanceTimersByTimeAsync(10_100);
  await rejection;
});
