import { expect, test } from "vitest";
import { createDatabase } from "../../db";
import { createTestCaller } from "../../lib/test";
import { createAuth } from "..";

test("Expo email login authenticates protected tRPC and sign-out revokes the session", async () => {
  const db = createDatabase("unused");
  const auth = createAuth({
    db,
    secret: "test-only-secret-7b9f3d8a2c6e4f015d0a",
    baseURL: "http://localhost:3000",
  });
  const credentials = {
    email: "mobile@example.com",
    password: "test-password-12345",
  };
  const request = (path: string, body: object, cookie = "") =>
    auth.handler(
      new Request(`http://localhost:3000/api/auth/${path}`, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "expo-origin": "expo-starter://",
          "x-skip-oauth-proxy": "true",
          cookie,
        },
        body: JSON.stringify(body),
      }),
    );
  expect(
    (await request("sign-up/email", { ...credentials, name: "Mobile user" }))
      .status,
  ).toBe(200);
  expect(
    (
      await request("sign-in/email", {
        ...credentials,
        password: "wrong-password",
      })
    ).status,
  ).toBe(401);
  const login = await request("sign-in/email", credentials);
  expect(login.status).toBe(200);
  const cookie = login.headers
    .getSetCookie()
    .map((value) => value.split(";")[0])
    .join("; ");
  expect(cookie).toContain("better-auth.session_token=");
  const caller = () =>
    createTestCaller({
      db,
      headers: new Headers({ cookie }),
      getSession: (headers) => auth.api.getSession({ headers }),
    });
  expect(await caller().user.me()).toMatchObject({ email: credentials.email });
  expect((await request("sign-out", {}, cookie)).status).toBe(200);
  await expect(caller().user.me()).rejects.toMatchObject({
    code: "UNAUTHORIZED",
  });
});

test.each([
  "http://localhost:5173",
  "http://192.168.1.20:3000",
  "https://external.example.net",
])("Better Auth accepts authentication requests from %s", async (origin) => {
  const auth = createAuth({
    db: createDatabase("postgresql://unused:unused@localhost/unused"),
    secret: "test-only-secret-7b9f3d8a2c6e4f015d0a",
    baseURL: "http://localhost:3000",
  });

  const response = await auth.handler(
    new Request("http://localhost:3000/api/auth/sign-up/email", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        origin,
        // 带 Cookie 的跨站请求必须经过 Better Auth 的 origin 校验。
        cookie: "origin-check=1",
        "sec-fetch-site": "cross-site",
        "sec-fetch-mode": "cors",
      },
      body: JSON.stringify({
        name: "Origin test",
        email: "origin@example.com",
        password: "test-password-12345",
      }),
    }),
  );

  expect(response.status).toBe(200);
  expect(await response.json()).toMatchObject({
    user: { email: "origin@example.com" },
  });
});

test("Better Auth persists users and resolves sessions through PGlite", async () => {
  const db = createDatabase("postgresql://unused:unused@localhost/unused");
  const auth = createAuth({
    db,
    secret: "test-only-secret-7b9f3d8a2c6e4f015d0a",
    baseURL: "http://localhost:3000",
  });
  const response = await auth.api.signUpEmail({
    body: {
      name: "Alice",
      email: "alice@example.com",
      password: "test-password-12345",
    },
    asResponse: true,
  });
  expect(response.status).toBe(200);

  const cookie = response.headers
    .getSetCookie()
    .map((value) => value.split(";")[0])
    .join("; ");
  const authSession = await auth.api.getSession({
    headers: new Headers({ cookie }),
  });
  const storedUser = await db.query.user.findFirst();
  expect(storedUser).toMatchObject({ email: "alice@example.com" });
  expect(authSession?.user.id).toBe(storedUser?.id);
  expect(await db.query.session.findFirst()).toMatchObject({
    userId: storedUser?.id,
    token: authSession?.session.token,
  });
  expect(await db.query.account.findFirst()).toMatchObject({
    userId: storedUser?.id,
    providerId: "credential",
    password: expect.any(String),
  });
});
