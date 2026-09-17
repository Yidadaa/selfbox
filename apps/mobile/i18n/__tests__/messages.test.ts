import { expect, test } from "vitest";
import { messages as en } from "../en";
import { formatDate, formatTime, getMessages, resolveLanguage } from "../index";
import { messages as zh } from "../zh";

test("resolves system language with English fallback and honors explicit choices", () => {
  expect(resolveLanguage("system", "zh-Hans-CN")).toBe("zh");
  expect(resolveLanguage("system", "fr")).toBe("en");
  expect(resolveLanguage("system", null)).toBe("en");
  expect(resolveLanguage("en", "zh")).toBe("en");
  expect(getMessages("zh").monologue).toBe("我的独白");
  expect(getMessages("en").monologue).toBe("My monologue");
});

test("both dictionaries have matching nonempty text and localized dates", () => {
  expect(Object.keys(zh).sort()).toEqual(Object.keys(en).sort());
  for (const value of Object.values(zh))
    expect(
      typeof value === "string"
        ? value.length > 0
        : Object.values(value).every(Boolean),
    ).toBe(true);
  expect(Object.keys(zh.iconNames)).toEqual(Object.keys(en.iconNames));
  const date = new Date(2026, 8, 17, 14, 30).getTime();
  expect(formatDate(date, "en")).toContain("2026");
  expect(formatDate(date, "zh")).toContain("9月");
  expect(formatTime(date, "zh")).toContain("14:30");
});
