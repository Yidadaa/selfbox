import { router } from "expo-router";
import { Button } from "heroui-native/button";
import { Dialog } from "heroui-native/dialog";
import { Surface } from "heroui-native/surface";
import {
  Check,
  ChevronRight,
  Code2,
  Languages,
  MessageCircle,
  Monitor,
  Moon,
  Palette,
  Sun,
  Trash2,
  UserRound,
} from "lucide-react-native";
import { useState } from "react";
import { Alert, Pressable, ScrollView, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { preferencesStore, useAppearance } from "@/components/appearance";
import { useDatabase } from "@/components/database";
import { SafeAreaView } from "@/components/safe-area";
import { pruneAttachments } from "@/lib/attachments";

export default function SettingsPage() {
  const { colors, messages, preferences, bubble, bubbleText } = useAppearance();
  const { repository, refresh } = useDatabase();
  const [section, setSection] = useState<
    "theme" | "language" | "chatStyle" | null
  >(null);
  const insets = useSafeAreaInsets();
  const chevron = (
    <ChevronRight size={17} color={colors.muted} strokeWidth={1.6} />
  );
  const options =
    section === "theme"
      ? ([
          { value: "system", label: messages.system, icon: Monitor },
          { value: "light", label: messages.light, icon: Sun },
          { value: "dark", label: messages.dark, icon: Moon },
        ] as const)
      : section === "language"
        ? ([
            { value: "system", label: messages.system, icon: Monitor },
            { value: "zh", label: messages.chinese, icon: Languages },
            { value: "en", label: messages.english, icon: Languages },
          ] as const)
        : ([
            { value: "blue", label: messages.blue, icon: MessageCircle },
            { value: "green", label: messages.green, icon: MessageCircle },
            { value: "mono", label: messages.mono, icon: MessageCircle },
          ] as const);
  function clearData() {
    Alert.alert(messages.clearDataTitle, messages.clearDataHint, [
      { text: messages.cancel, style: "cancel" },
      {
        text: messages.delete,
        style: "destructive",
        onPress: () => {
          try {
            repository.clear();
            refresh();
            pruneAttachments([]);
            Alert.alert(messages.clearDataDone);
          } catch {
            Alert.alert(messages.saveError);
          }
        },
      },
    ]);
  }
  return (
    <SafeAreaView
      edges={["top", "left", "right"]}
      className="flex-1 bg-background"
    >
      <ScrollView
        contentContainerStyle={{
          padding: 24,
          paddingBottom: insets.bottom + 112,
        }}
      >
        <Text className="mb-7 mt-3 text-4xl font-bold tracking-tight text-foreground">
          {messages.settings}
        </Text>
        <Surface className="rounded-3xl p-0 bg-surface">
          <Pressable
            accessibilityRole="button"
            onPress={() => router.push("/account")}
            className="flex-row items-center gap-4 p-5"
          >
            <View className="h-14 w-14 items-center justify-center">
              <UserRound size={29} color={colors.muted} strokeWidth={1.6} />
            </View>
            <View className="flex-1 gap-1.5">
              <Text className="text-lg font-semibold text-accent">
                {messages.accountHint}
              </Text>
              <Text className="text-xs text-muted">
                {messages.accountDescription}
              </Text>
            </View>
            {chevron}
          </Pressable>
        </Surface>
        <Text className="mb-2.5 ml-3 mt-8 text-xs font-medium text-muted">
          {messages.appearance}
        </Text>
        <Surface className="overflow-hidden rounded-3xl p-0 bg-surface">
          <Button
            variant="ghost"
            className="min-h-16 flex-row justify-start gap-3 px-4 py-3"
            onPress={() => setSection("theme")}
          >
            <Palette size={19} color={colors.accent} />
            <Text className="flex-1 text-base text-foreground">
              {messages.theme}
            </Text>
            <Text className="text-sm text-muted">
              {messages[preferences.theme]}
            </Text>
            {chevron}
          </Button>
          <View className="ml-15 h-px bg-border" />
          <Button
            variant="ghost"
            className="min-h-16 flex-row justify-start gap-3 px-4 py-3"
            onPress={() => setSection("language")}
          >
            <Languages size={19} color={colors.accent} />
            <Text className="flex-1 text-base text-foreground">
              {messages.language}
            </Text>
            <Text className="text-sm text-muted">
              {preferences.language === "system"
                ? messages.system
                : preferences.language === "zh"
                  ? messages.chinese
                  : messages.english}
            </Text>
            {chevron}
          </Button>
          <View className="ml-15 h-px bg-border" />
          <Button
            variant="ghost"
            className="min-h-16 flex-row justify-start gap-3 px-4 py-3"
            onPress={() => setSection("chatStyle")}
          >
            <MessageCircle size={19} color={colors.accent} />
            <Text className="flex-1 text-base text-foreground">
              {messages.chatStyle}
            </Text>
            <Text className="text-sm text-muted">
              {messages[preferences.chatStyle]}
            </Text>
            {chevron}
          </Button>
        </Surface>
        <Text className="mb-2.5 ml-3 mt-8 text-xs font-medium text-muted">
          {messages.data}
        </Text>
        <Surface className="overflow-hidden rounded-3xl p-0 bg-surface">
          <Button
            variant="ghost"
            className="min-h-16 flex-row justify-start gap-3 px-4 py-3"
            onPress={clearData}
          >
            <Trash2 size={19} color={colors.danger} />
            <Text className="flex-1 text-base text-danger">
              {messages.clearData}
            </Text>
            {chevron}
          </Button>
        </Surface>
        <Text className="ml-3 mt-3 text-xs text-muted">
          {messages.localOnly}
        </Text>
        {__DEV__ && (
          <Surface className="mt-8 overflow-hidden rounded-3xl p-0 bg-surface">
            <Button
              variant="ghost"
              className="min-h-16 flex-row justify-start gap-3 px-4 py-3"
              onPress={() => router.push("/dev")}
            >
              <Code2 size={19} color={colors.accent} />
              <Text className="flex-1 text-base text-foreground">
                {messages.devLink}
              </Text>
              {chevron}
            </Button>
          </Surface>
        )}
        <View className="items-center gap-2 pt-10">
          <Text className="text-lg font-semibold tracking-tight text-muted">
            {messages.brand}
          </Text>
          <Text className="text-xs text-muted">{messages.about}</Text>
        </View>
      </ScrollView>
      <Dialog
        isOpen={section !== null}
        onOpenChange={(open) => !open && setSection(null)}
      >
        <Dialog.Portal>
          <Dialog.Overlay />
          <Dialog.Content className="w-[90%] rounded-3xl bg-surface p-5">
            <Dialog.Close variant="ghost" />
            <Dialog.Title className="mb-4 text-xl font-semibold text-foreground">
              {section ? messages[section] : ""}
            </Dialog.Title>
            {section === "chatStyle" && (
              <View
                className="mb-5 self-end rounded-[22px] px-5 py-3"
                style={{ backgroundColor: bubble }}
              >
                <Text style={{ color: bubbleText }}>
                  {messages.previewMessage}
                </Text>
              </View>
            )}
            {options.map(({ value, label, icon: Icon }) => (
              <Button
                key={value}
                variant="ghost"
                className="min-h-16 flex-row justify-start gap-3 px-4 py-3"
                onPress={() => {
                  if (
                    section === "theme" &&
                    (value === "system" ||
                      value === "light" ||
                      value === "dark")
                  )
                    preferencesStore.getState().update({ theme: value });
                  if (
                    section === "language" &&
                    (value === "system" || value === "zh" || value === "en")
                  )
                    preferencesStore.getState().update({ language: value });
                  if (
                    section === "chatStyle" &&
                    (value === "blue" || value === "green" || value === "mono")
                  )
                    preferencesStore.getState().update({ chatStyle: value });
                }}
              >
                <Icon size={19} color={colors.accent} />
                <Text className="flex-1 text-base text-foreground">
                  {label}
                </Text>
                {section && preferences[section] === value ? (
                  <Check size={21} color={colors.accent} />
                ) : null}
              </Button>
            ))}
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog>
    </SafeAreaView>
  );
}
