import { expect, test } from "vitest";
import { errorText } from "../errors";

test("shows the original message and nested SQLite cause", () => {
  const cause = new Error("table chats already exists");
  const error = new Error("Failed query: CREATE TABLE chats (...)\nparams: ", {
    cause,
  });
  expect(errorText(error)).toBe(
    "Failed query: CREATE TABLE chats (...)\nparams: \n\ntable chats already exists",
  );
});

test("supports native error objects, string errors and missing messages", () => {
  expect(
    errorText({ message: "Native SQLite error", cause: "database is locked" }),
  ).toBe("Native SQLite error\n\ndatabase is locked");
  expect(errorText("Unable to open database")).toBe("Unable to open database");
  expect(errorText({ code: "SQLITE_CANTOPEN" })).toContain("SQLITE_CANTOPEN");
  for (const error of [null, undefined, {}, "", new Error()])
    expect(errorText(error)).toBeNull();
});

test("stops on circular causes instead of crashing the error screen", () => {
  const error = new Error("SQLite error");
  error.cause = error;
  expect(errorText(error)).toBe("SQLite error");
  const object: { self?: unknown } = {};
  object.self = object;
  expect(errorText(object)).toBeNull();
});
