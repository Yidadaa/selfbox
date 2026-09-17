import { router } from "expo-router";
import { Button } from "heroui-native/button";
import { Input } from "heroui-native/input";
import { ArrowLeft, Check } from "lucide-react-native";
import { useRef, useState } from "react";
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  Text,
  View,
} from "react-native";
import { useAppearance } from "@/components/appearance";
import { useDatabase } from "@/components/database";
import { ChatIcon, chatIcons } from "@/components/icons";
import { SafeAreaView } from "@/components/safe-area";
import {
  type ChatIcon as ChatIconValue,
  chatInputSchema,
  iconNames,
} from "@/db/payload";

export default function CreateChatPage() {
  const { colors, messages } = useAppearance();
  const { repository, refresh } = useDatabase();
  const [name, setName] = useState("");
  const [icon, setIcon] = useState<ChatIconValue>({
    type: "lucide",
    name: "message",
  });
  const [emoji, setEmoji] = useState("");
  const [mode, setMode] = useState<"lucide" | "emoji">("lucide");
  const [error, setError] = useState<string | null>(null);
  const creating = useRef(false);
  const selected =
    mode === "emoji" ? { type: "emoji" as const, value: emoji } : icon;
  function create() {
    if (creating.current) return;
    const parsed = chatInputSchema.safeParse({ name, icon: selected });
    if (!parsed.success) {
      setError(messages.invalidChat);
      return;
    }
    try {
      creating.current = true;
      const id = repository.createChat(parsed.data);
      refresh();
      router.replace({ pathname: "/chat/[id]", params: { id } });
    } catch {
      creating.current = false;
      setError(messages.saveError);
    }
  }
  return (
    <SafeAreaView className="flex-1 bg-background">
      <View
        className="flex-row items-center gap-1 border-b-border px-3 py-2"
        style={{ borderBottomWidth: 0.5 }}
      >
        <Button
          accessibilityLabel={messages.back}
          isIconOnly
          variant="ghost"
          className="h-11 w-11 rounded-full"
          onPress={() => {
            if (router.canGoBack()) router.back();
            else router.replace("/");
          }}
        >
          <ArrowLeft size={23} color={colors.text} strokeWidth={1.8} />
        </Button>
        <Text className="flex-1 px-1 text-lg font-semibold text-foreground">
          {messages.newChat}
        </Text>
      </View>
      <KeyboardAvoidingView
        className="flex-1"
        behavior={Platform.OS === "ios" ? "padding" : "height"}
      >
        <ScrollView
          keyboardShouldPersistTaps="handled"
          contentContainerStyle={{ padding: 24, gap: 24 }}
        >
          <View className="items-center gap-4 py-3">
            <ChatIcon
              icon={mode === "emoji" && !emoji ? icon : selected}
              size={82}
            />
            <Text className="text-center text-sm text-muted">
              {messages.newChatHint}
            </Text>
          </View>
          <View className="gap-2.5">
            <Text className="text-sm font-semibold text-foreground">
              {messages.chatName}
            </Text>
            <Input
              accessibilityLabel={messages.chatName}
              placeholder={messages.chatNamePlaceholder}
              value={name}
              onChangeText={setName}
              maxLength={60}
              returnKeyType="done"
              onSubmitEditing={create}
            />
          </View>
          <View className="gap-4">
            <Text className="text-sm font-semibold text-foreground">
              {messages.chooseIcon}
            </Text>
            <View className="flex-row rounded-2xl p-1 bg-elevated">
              {(["lucide", "emoji"] as const).map((value) => (
                <Pressable
                  key={value}
                  accessibilityRole="tab"
                  accessibilityState={{ selected: mode === value }}
                  onPress={() => setMode(value)}
                  className="flex-1 items-center rounded-xl py-3"
                  style={{
                    backgroundColor:
                      mode === value ? colors.surface : "transparent",
                  }}
                >
                  <Text
                    className="font-medium"
                    style={{
                      color: mode === value ? colors.text : colors.muted,
                    }}
                  >
                    {value === "lucide"
                      ? messages.lucideIcons
                      : messages.emojiIcon}
                  </Text>
                </Pressable>
              ))}
            </View>
            {mode === "lucide" ? (
              <View className="flex-row flex-wrap gap-3">
                {iconNames.map((name) => {
                  const Icon = chatIcons[name];
                  const active = icon.type === "lucide" && icon.name === name;
                  return (
                    <Pressable
                      accessibilityRole="button"
                      accessibilityLabel={messages.iconNames[name]}
                      accessibilityState={{ selected: active }}
                      key={name}
                      onPress={() => setIcon({ type: "lucide", name })}
                      className="h-16 w-16 items-center justify-center rounded-2xl"
                      style={{
                        borderWidth: 1.5,
                        borderColor: active ? colors.accent : colors.border,
                      }}
                    >
                      <Icon
                        color={active ? colors.accent : colors.muted}
                        size={26}
                        strokeWidth={1.7}
                      />
                      {active && (
                        <View className="absolute right-1 top-1">
                          <Check size={10} color={colors.accent} />
                        </View>
                      )}
                    </Pressable>
                  );
                })}
              </View>
            ) : (
              <Input
                accessibilityLabel={messages.emojiHint}
                placeholder={messages.emojiHint}
                value={emoji}
                onChangeText={setEmoji}
                maxLength={32}
              />
            )}
          </View>
          {error && (
            <Text accessibilityRole="alert" className="text-danger">
              {error}
            </Text>
          )}
          <Button onPress={create}>{messages.createChat}</Button>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
