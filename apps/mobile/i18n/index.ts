import type { Preferences } from "@/lib/preferences";
import { messages as en } from "./en";
import { messages as zh } from "./zh";

export type Messages = {
  [K in keyof typeof en]: (typeof en)[K] extends string
    ? string
    : { [P in keyof (typeof en)[K]]: string };
};
export type Language = "zh" | "en";

export function resolveLanguage(
  preference: Preferences["language"],
  deviceLanguage?: string | null,
): Language {
  return preference === "system"
    ? deviceLanguage?.toLowerCase().startsWith("zh")
      ? "zh"
      : "en"
    : preference;
}

export function getMessages(language: Language): Messages {
  return language === "zh" ? zh : en;
}

export function formatTime(timestamp: number, language: Language) {
  return new Intl.DateTimeFormat(language === "zh" ? "zh-CN" : "en-US", {
    hour: "numeric",
    minute: "2-digit",
  }).format(timestamp);
}

export function formatDate(timestamp: number, language: Language) {
  return new Intl.DateTimeFormat(language === "zh" ? "zh-CN" : "en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  }).format(timestamp);
}
