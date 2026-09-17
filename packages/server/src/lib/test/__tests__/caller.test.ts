import { expect, test, vi } from "vitest";
import { createTestCaller, createTestUser } from "..";

test("callers keep their users isolated", async () => {
  const alice = await createTestUser({ name: "Alice" });
  const bob = await createTestUser({ name: "Bob" });
  const aliceCaller = createTestCaller({ user: alice });
  const bobCaller = createTestCaller({ user: bob });
  const anonymousCaller = createTestCaller();

  const results = await Promise.all([
    aliceCaller.user.me(),
    bobCaller.user.me(),
    aliceCaller.user.me(),
  ]);
  expect(results.map((user) => user.id)).toEqual([alice.id, bob.id, alice.id]);
  await expect(anonymousCaller.user.me()).rejects.toMatchObject({
    code: "UNAUTHORIZED",
  });
});

test("custom session lookup receives headers and is cached per caller", async () => {
  const user = await createTestUser();
  const headers = new Headers({ cookie: "test-session=expired" });
  const getSession = vi.fn(async () => null);
  const caller = createTestCaller({ user, headers, getSession });

  // 显式 getSession 优先于 user，匿名结果也必须复用请求缓存。
  await expect(caller.user.me()).rejects.toMatchObject({
    code: "UNAUTHORIZED",
  });
  await expect(caller.user.me()).rejects.toMatchObject({
    code: "UNAUTHORIZED",
  });
  expect(getSession).toHaveBeenCalledExactlyOnceWith(headers);

  const nextCaller = createTestCaller({ headers, getSession });
  await expect(nextCaller.user.me()).rejects.toMatchObject({
    code: "UNAUTHORIZED",
  });
  expect(getSession).toHaveBeenCalledTimes(2);
});
