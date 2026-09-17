import AsyncStorage from "@react-native-async-storage/async-storage";
import { useLocales } from "expo-localization";
import { useCSSVariable, useUniwind } from "uniwind";
import { useStore } from "zustand";
import { getMessages, resolveLanguage } from "@/i18n";
import { createPreferencesStore } from "@/lib/preferences";

export const preferencesStore = createPreferencesStore(AsyncStorage);

export function useAppearance() {
  const preferences = useStore(preferencesStore);
  const { theme } = useUniwind();
  const locales = useLocales();
  const language = resolveLanguage(
    preferences.language,
    locales[0]?.languageCode,
  );
  // 原生图标、导航及 Markdown 需要具体颜色，其余界面优先使用语义 className。
  const [
    background,
    surface,
    elevated,
    text,
    muted,
    border,
    accent,
    accentSoft,
    incoming,
    danger,
    accentForeground,
    markdownCode,
    bubble,
    bubbleText,
  ] = useCSSVariable([
    "--color-background",
    "--color-surface",
    "--color-elevated",
    "--color-foreground",
    "--color-muted",
    "--color-border",
    "--color-accent",
    "--color-accent-soft",
    "--color-incoming",
    "--color-danger",
    "--color-accent-foreground",
    "--color-markdown-code",
    `--color-bubble-${preferences.chatStyle}`,
    `--color-bubble-${preferences.chatStyle}-foreground`,
  ]);
  return {
    preferences,
    language,
    messages: getMessages(language),
    dark: theme === "dark",
    colors: {
      background: background as string,
      surface: surface as string,
      elevated: elevated as string,
      text: text as string,
      muted: muted as string,
      border: border as string,
      accent: accent as string,
      accentSoft: accentSoft as string,
      incoming: incoming as string,
      danger: danger as string,
      accentForeground: accentForeground as string,
      markdownCode: markdownCode as string,
    },
    bubble: bubble as string,
    bubbleText: bubbleText as string,
  };
}
