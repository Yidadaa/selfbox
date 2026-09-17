import { router } from "expo-router";
import { Button } from "heroui-native/button";
import { Dialog } from "heroui-native/dialog";
import { Label } from "heroui-native/label";
import { ListGroup } from "heroui-native/list-group";
import { Radio } from "heroui-native/radio";
import { RadioGroup } from "heroui-native/radio-group";
import { Separator } from "heroui-native/separator";
import { Surface } from "heroui-native/surface";
import { Typography } from "heroui-native/text";
import {
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
import { Fragment, useState } from "react";
import { ScrollView, View } from "react-native";
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
  const [clearDialog, setClearDialog] = useState<
    "confirm" | "success" | "error" | null
  >(null);
  const insets = useSafeAreaInsets();
  const settings = [
    {
      key: "theme",
      icon: Palette,
      value: messages[preferences.theme],
    },
    {
      key: "language",
      icon: Languages,
      value:
        preferences.language === "system"
          ? messages.system
          : preferences.language === "zh"
            ? messages.chinese
            : messages.english,
    },
    {
      key: "chatStyle",
      icon: MessageCircle,
      value: messages[preferences.chatStyle],
    },
  ] as const;
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
    try {
      repository.clear();
      refresh();
      pruneAttachments([]);
      setClearDialog("success");
    } catch {
      setClearDialog("error");
    }
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
          gap: 28,
        }}
      >
        <Typography.Heading className="mt-3">
          {messages.settings}
        </Typography.Heading>

        <ListGroup className="shadow-none">
          <ListGroup.Item
            accessibilityRole="button"
            onPress={() => router.push("/account")}
          >
            <ListGroup.ItemPrefix>
              <UserRound size={24} color={colors.accent} strokeWidth={1.8} />
            </ListGroup.ItemPrefix>
            <ListGroup.ItemContent>
              <ListGroup.ItemTitle>{messages.accountHint}</ListGroup.ItemTitle>
              <ListGroup.ItemDescription>
                {messages.accountDescription}
              </ListGroup.ItemDescription>
            </ListGroup.ItemContent>
            <ListGroup.ItemSuffix />
          </ListGroup.Item>
        </ListGroup>

        <View className="gap-3">
          <Typography.Heading type="h6" color="muted" className="px-4">
            {messages.appearance}
          </Typography.Heading>
          <ListGroup className="shadow-none">
            {settings.map(({ key, icon: Icon, value }, index) => (
              <Fragment key={key}>
                {index > 0 && <Separator className="mx-4" />}
                <ListGroup.Item
                  accessibilityRole="button"
                  onPress={() => setSection(key)}
                >
                  <ListGroup.ItemPrefix>
                    <Icon size={22} color={colors.accent} strokeWidth={1.8} />
                  </ListGroup.ItemPrefix>
                  <ListGroup.ItemContent>
                    <ListGroup.ItemTitle>{messages[key]}</ListGroup.ItemTitle>
                    <ListGroup.ItemDescription>
                      {value}
                    </ListGroup.ItemDescription>
                  </ListGroup.ItemContent>
                  <ListGroup.ItemSuffix />
                </ListGroup.Item>
              </Fragment>
            ))}
          </ListGroup>
        </View>

        <View className="gap-3">
          <Typography.Heading type="h6" color="muted" className="px-4">
            {messages.data}
          </Typography.Heading>
          <ListGroup className="shadow-none">
            <ListGroup.Item
              accessibilityRole="button"
              onPress={() => setClearDialog("confirm")}
            >
              <ListGroup.ItemPrefix>
                <Trash2 size={22} color={colors.danger} strokeWidth={1.8} />
              </ListGroup.ItemPrefix>
              <ListGroup.ItemContent>
                <ListGroup.ItemTitle className="text-danger">
                  {messages.clearData}
                </ListGroup.ItemTitle>
              </ListGroup.ItemContent>
              <ListGroup.ItemSuffix />
            </ListGroup.Item>
          </ListGroup>
          <Typography type="body-xs" color="muted" className="px-4">
            {messages.localOnly}
          </Typography>
        </View>

        {__DEV__ && (
          <ListGroup className="shadow-none">
            <ListGroup.Item
              accessibilityRole="button"
              onPress={() => router.push("/dev")}
            >
              <ListGroup.ItemPrefix>
                <Code2 size={22} color={colors.accent} strokeWidth={1.8} />
              </ListGroup.ItemPrefix>
              <ListGroup.ItemContent>
                <ListGroup.ItemTitle>{messages.devLink}</ListGroup.ItemTitle>
              </ListGroup.ItemContent>
              <ListGroup.ItemSuffix />
            </ListGroup.Item>
          </ListGroup>
        )}

        <View className="gap-1 pb-2">
          <Typography type="h5" color="muted" align="center">
            {messages.brand}
          </Typography>
          <Typography type="body-xs" color="muted" align="center">
            {messages.about}
          </Typography>
        </View>
      </ScrollView>

      <Dialog
        isOpen={section !== null}
        onOpenChange={(open) => !open && setSection(null)}
      >
        <Dialog.Portal>
          <Dialog.Overlay />
          <Dialog.Content className="gap-5">
            <View className="flex-row items-center justify-between gap-3">
              <Dialog.Title className="flex-1">
                {section ? messages[section] : ""}
              </Dialog.Title>
              <Dialog.Close accessibilityLabel={messages.close} />
            </View>
            {section === "chatStyle" && (
              <Surface
                className="self-end shadow-none"
                style={{ backgroundColor: bubble }}
              >
                <Typography style={{ color: bubbleText }}>
                  {messages.previewMessage}
                </Typography>
              </Surface>
            )}
            <RadioGroup
              accessibilityLabel={section ? messages[section] : undefined}
              value={section ? preferences[section] : undefined}
              onValueChange={(value) => {
                if (
                  section === "theme" &&
                  (value === "system" || value === "light" || value === "dark")
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
              {options.map(({ value, label, icon: Icon }) => (
                <RadioGroup.Item key={value} value={value} className="min-h-12">
                  {({ isSelected }) => (
                    <>
                      <Icon
                        size={22}
                        color={isSelected ? colors.accent : colors.muted}
                        strokeWidth={1.8}
                      />
                      <Label className="flex-1">{label}</Label>
                      <Radio />
                    </>
                  )}
                </RadioGroup.Item>
              ))}
            </RadioGroup>
            <Button onPress={() => setSection(null)}>{messages.done}</Button>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog>

      <Dialog
        isOpen={clearDialog !== null}
        onOpenChange={(open) => !open && setClearDialog(null)}
      >
        <Dialog.Portal>
          <Dialog.Overlay />
          <Dialog.Content className="gap-5">
            <View className="flex-row items-center justify-between gap-3">
              <Dialog.Title className="flex-1">
                {clearDialog === "confirm"
                  ? messages.clearDataTitle
                  : messages.clearData}
              </Dialog.Title>
              <Dialog.Close accessibilityLabel={messages.close} />
            </View>
            <Dialog.Description accessibilityLiveRegion="polite">
              {clearDialog === "confirm"
                ? messages.clearDataHint
                : clearDialog === "success"
                  ? messages.clearDataDone
                  : messages.saveError}
            </Dialog.Description>
            {clearDialog === "confirm" ? (
              <View className="gap-3">
                <Button variant="danger" onPress={clearData}>
                  {messages.delete}
                </Button>
                <Button variant="tertiary" onPress={() => setClearDialog(null)}>
                  {messages.cancel}
                </Button>
              </View>
            ) : (
              <Button onPress={() => setClearDialog(null)}>
                {messages.done}
              </Button>
            )}
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog>
    </SafeAreaView>
  );
}
