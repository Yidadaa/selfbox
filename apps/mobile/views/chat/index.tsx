import { BlurTargetView } from "expo-blur";
import * as ImagePicker from "expo-image-picker";
import { router, useLocalSearchParams } from "expo-router";
import { Button } from "heroui-native/button";
import { Menu } from "heroui-native/menu";
import {
  ArrowLeft,
  ListFilter,
  NotebookPen,
  Pencil,
  Pin,
  PinOff,
  Trash2,
} from "lucide-react-native";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  Alert,
  FlatList,
  Keyboard,
  KeyboardAvoidingView,
  Platform,
  StyleSheet,
  Text,
  type TextInput,
  useWindowDimensions,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useAppearance } from "@/components/appearance";
import { useDatabase } from "@/components/database";
import { SafeAreaView } from "@/components/safe-area";
import { editPayload, messageText, type Payload } from "@/db/payload";
import type { Message } from "@/db/schema";
import { formatDate } from "@/i18n";
import {
  attachmentUri,
  importAttachment,
  pruneAttachments,
} from "@/lib/attachments";
import { MessageBubble } from "./bubble";
import { Composer } from "./composer";
import { Glass } from "./glass";

export default function ChatPage() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const database = useDatabase();
  const { repository, refresh } = database;
  const { colors, messages, language } = useAppearance();
  const { chat, items, pinned } = useMemo(() => {
    const items = database.repository.listMessages(id);
    return {
      chat: database.repository.getChat(id),
      items,
      pinned: items.filter((message) => message.pinnedAt !== null),
    };
  }, [database, id]);
  const list = useRef<FlatList<Message>>(null);
  const input = useRef<TextInput>(null);
  const { height } = useWindowDimensions();
  const insets = useSafeAreaInsets();
  const blurTarget = useRef<View>(null);
  const [viewportHeight, setViewportHeight] = useState(height);
  const [availableHeight, setAvailableHeight] = useState(height);
  const [headerHeight, setHeaderHeight] = useState(insets.top + 68);
  const [composerHeight, setComposerHeight] = useState(insets.bottom + 76);
  const [keyboardVisible, setKeyboardVisible] = useState(Keyboard.isVisible());
  const keyboardInset = Math.max(0, viewportHeight - availableHeight);

  useEffect(() => {
    const show = Keyboard.addListener("keyboardDidShow", () =>
      setKeyboardVisible(true),
    );
    const hide = Keyboard.addListener("keyboardDidHide", () =>
      setKeyboardVisible(false),
    );
    return () => {
      show.remove();
      hide.remove();
    };
  }, []);
  const [text, setText] = useState("");
  const [photo, setPhoto] = useState<ImagePicker.ImagePickerAsset | null>(null);
  const [selected, setSelected] = useState<Message | null>(null);
  const [editing, setEditing] = useState<Message | null>(null);
  const [showPins, setShowPins] = useState(false);
  const visibleItems = showPins ? pinned : items;
  const PinFilterIcon = showPins ? ListFilter : Pin;
  const [busy, setBusy] = useState(false);
  const busyRef = useRef(false);
  const [error, setError] = useState<string | null>(null);
  const draft = useRef<{
    text: string;
    photo: ImagePicker.ImagePickerAsset | null;
  } | null>(null);

  function finishEdit() {
    setEditing(null);
    setText(draft.current?.text ?? "");
    setPhoto(draft.current?.photo ?? null);
    draft.current = null;
    setError(null);
  }
  function send() {
    if (busyRef.current || !chat) return;
    if (!text.trim() && !photo && editing?.payload.type !== "image") return;
    busyRef.current = true;
    setBusy(true);
    setError(null);
    try {
      if (editing) {
        repository.edit(
          editing.id,
          photo
            ? {
                version: 1,
                type: "image",
                image: importAttachment(photo),
                caption: text,
              }
            : editPayload(editing.payload, text),
        );
        finishEdit();
      } else {
        const payload: Payload = photo
          ? {
              version: 1,
              type: "image",
              image: importAttachment(photo),
              caption: text,
            }
          : { version: 1, type: "text", text };
        repository.send(id, payload);
        setText("");
        setPhoto(null);
      }
      refresh();
      try {
        pruneAttachments(repository.imageFiles());
      } catch {
        /* 下次启动重试清理 */
      }
      list.current?.scrollToOffset({ offset: 0, animated: true });
    } catch {
      setError(messages.saveError);
    } finally {
      busyRef.current = false;
      setBusy(false);
    }
  }
  async function pickPhoto() {
    if (busyRef.current) return;
    busyRef.current = true;
    setBusy(true);
    setError(null);
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ["images"],
        quality: 0.9,
      });
      if (!result.canceled && result.assets[0]) setPhoto(result.assets[0]);
    } catch {
      setError(messages.imageError);
    } finally {
      busyRef.current = false;
      setBusy(false);
    }
  }
  function togglePin(message: Message) {
    try {
      repository.togglePin(message.id);
      refresh();
      setSelected(null);
    } catch {
      setError(messages.saveError);
    }
  }
  function remove(message: Message) {
    setSelected(null);
    Alert.alert(messages.deleteMessage, messages.deleteMessageHint, [
      { text: messages.cancel, style: "cancel" },
      {
        text: messages.delete,
        style: "destructive",
        onPress: () => {
          try {
            repository.deleteMessage(message.id);
            if (editing?.id === message.id) finishEdit();
            refresh();
            try {
              pruneAttachments(repository.imageFiles());
            } catch {
              /* 下次启动重试清理 */
            }
          } catch {
            setError(messages.saveError);
          }
        },
      },
    ]);
  }
  function startEdit(message: Message) {
    if (!editing) draft.current = { text, photo };
    setEditing(message);
    setSelected(null);
    setPhoto(null);
    setText(messageText(message.payload));
    setError(null);
    requestAnimationFrame(() => input.current?.focus());
  }
  const canSend =
    !busy && (!!text.trim() || !!photo || editing?.payload.type === "image");
  return (
    <Menu
      asChild
      presentation="popover"
      isOpen={selected !== null}
      onOpenChange={(open) => {
        if (!open) setSelected(null);
      }}
    >
      <SafeAreaView
        edges={[]}
        className="flex-1 bg-background"
        onLayout={({ nativeEvent }) =>
          setViewportHeight(nativeEvent.layout.height)
        }
      >
        <BlurTargetView ref={blurTarget} style={StyleSheet.absoluteFill}>
          {visibleItems.length ? (
            <FlatList
              ref={list}
              className="flex-1"
              data={visibleItems}
              inverted
              keyExtractor={(item) => item.id}
              keyboardDismissMode="interactive"
              keyboardShouldPersistTaps="handled"
              contentInsetAdjustmentBehavior="never"
              automaticallyAdjustKeyboardInsets={false}
              contentContainerStyle={{
                // inverted 会翻转内容方向：paddingTop 对应屏幕底部。
                paddingTop: composerHeight + keyboardInset + 16,
                paddingBottom: headerHeight + 16,
                paddingLeft: insets.left,
                paddingRight: insets.right,
              }}
              scrollIndicatorInsets={{
                top: headerHeight,
                bottom: composerHeight + keyboardInset,
              }}
              renderItem={({ item, index }) => {
                const older = visibleItems[index + 1];
                const showDate =
                  !older ||
                  new Date(older.createdAt).toDateString() !==
                    new Date(item.createdAt).toDateString();
                return (
                  <View>
                    {showDate && (
                      <Text className="py-5 text-center text-xs font-medium text-muted">
                        {formatDate(item.createdAt, language)}
                      </Text>
                    )}
                    <MessageBubble
                      message={item}
                      onLongPress={() => {
                        Keyboard.dismiss();
                        setSelected(item);
                      }}
                    />
                  </View>
                );
              }}
            />
          ) : (
            <View
              className="flex-1 items-center justify-center gap-4 px-10"
              style={{
                paddingTop: headerHeight + 16,
                paddingBottom: composerHeight + keyboardInset + 16,
              }}
            >
              <View className="mb-2 h-20 w-20 items-center justify-center">
                {showPins ? (
                  <Pin color={colors.accent} size={32} strokeWidth={1.4} />
                ) : (
                  <NotebookPen
                    color={colors.accent}
                    size={32}
                    strokeWidth={1.4}
                  />
                )}
              </View>
              <Text className="text-xl font-semibold text-foreground">
                {showPins ? messages.emptyPins : messages.emptyChat}
              </Text>
              <Text className="text-center text-sm leading-6 text-muted">
                {showPins ? messages.noPins : messages.emptyChatHint}
              </Text>
              {showPins && (
                <Button variant="ghost" onPress={() => setShowPins(false)}>
                  <Button.Label>{messages.showAllMessages}</Button.Label>
                </Button>
              )}
            </View>
          )}
        </BlurTargetView>
        <KeyboardAvoidingView
          pointerEvents="box-none"
          style={StyleSheet.absoluteFill}
          behavior={Platform.OS === "ios" ? "padding" : "height"}
        >
          <View
            pointerEvents="box-none"
            className="flex-1 justify-end"
            onLayout={({ nativeEvent }) =>
              setAvailableHeight(nativeEvent.layout.height)
            }
          >
            <View
              pointerEvents="box-none"
              style={{
                paddingBottom: keyboardVisible ? 0 : insets.bottom + 10,
                paddingLeft: insets.left,
                paddingRight: insets.right,
              }}
              onLayout={({ nativeEvent }) =>
                setComposerHeight(nativeEvent.layout.height)
              }
            >
              {error && (
                <Glass
                  blurTarget={blurTarget}
                  className="mx-4 rounded-2xl border border-border/60 px-4 py-2"
                >
                  <Text
                    accessibilityRole="alert"
                    className="text-sm text-danger"
                  >
                    {error}
                  </Text>
                </Glass>
              )}
              {chat && (
                <Composer
                  blurTarget={blurTarget}
                  inputRef={input}
                  text={text}
                  imageUri={
                    photo?.uri ??
                    (editing?.payload.type === "image"
                      ? attachmentUri(editing.payload.image)
                      : undefined)
                  }
                  editing={editing}
                  busy={busy}
                  canSend={canSend}
                  canRemoveImage={!!photo}
                  availableHeight={Math.max(0, availableHeight - headerHeight)}
                  onChangeText={setText}
                  onPickImage={() => void pickPhoto()}
                  onRemoveImage={() => setPhoto(null)}
                  onCancelEdit={finishEdit}
                  onSend={send}
                />
              )}
            </View>
          </View>
        </KeyboardAvoidingView>
        <View
          pointerEvents="box-none"
          className="absolute inset-x-0 top-0 z-10 flex-row justify-between items-center gap-3 px-4 pb-3"
          style={{
            paddingTop: insets.top + 8,
            paddingLeft: insets.left + 16,
            paddingRight: insets.right + 16,
          }}
          onLayout={({ nativeEvent }) =>
            setHeaderHeight(nativeEvent.layout.height)
          }
        >
          <View className="min-w-0 flex-1 flex-row gap-2">
            <Glass
              blurTarget={blurTarget}
              className="shrink-0 rounded-full border border-border/60"
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
            </Glass>
            <Glass
              blurTarget={blurTarget}
              className="min-w-0 shrink justify-center rounded-full border border-border/60 px-5 py-2"
            >
              <Text numberOfLines={1} className="font-semibold text-foreground">
                {chat
                  ? chat.isDefault
                    ? messages.monologue
                    : chat.name
                  : messages.missingChat}
              </Text>
            </Glass>
          </View>
          <Glass
            blurTarget={blurTarget}
            className="rounded-full border border-border/60"
          >
            <Button
              accessibilityLabel={`${messages.pinned}: ${pinned.length}`}
              accessibilityHint={
                showPins
                  ? messages.showAllMessages
                  : messages.showPinnedMessages
              }
              accessibilityState={{ selected: showPins }}
              variant="ghost"
              className="h-11 gap-2 rounded-full px-3"
              onPress={() => {
                Keyboard.dismiss();
                setShowPins((value) => !value);
                list.current?.scrollToOffset({ offset: 0, animated: false });
              }}
            >
              <PinFilterIcon
                size={20}
                color={showPins ? colors.accent : ""}
                strokeWidth={showPins ? 2.2 : 1.8}
              />
              <Button.Label className={showPins ? "text-accent" : ""}>
                {showPins ? `${messages.pinnedOnly}` : pinned.length}
              </Button.Label>
            </Button>
          </Glass>
        </View>
        <Menu.Portal>
          <Menu.Overlay />
          <Menu.Content
            presentation="popover"
            placement="top"
            offset={0}
            align="center"
            width={200}
          >
            {selected && (
              <>
                <Menu.Item onPress={() => togglePin(selected)}>
                  {selected.pinnedAt !== null ? (
                    <PinOff size={19} color={colors.accent} />
                  ) : (
                    <Pin size={19} color={colors.accent} />
                  )}
                  <Menu.ItemTitle>
                    {selected.pinnedAt !== null ? messages.unpin : messages.pin}
                  </Menu.ItemTitle>
                </Menu.Item>
                <Menu.Item onPress={() => startEdit(selected)}>
                  <Pencil size={19} color={colors.accent} />
                  <Menu.ItemTitle>{messages.edit}</Menu.ItemTitle>
                </Menu.Item>
                <Menu.Item variant="danger" onPress={() => remove(selected)}>
                  <Trash2 size={19} color={colors.danger} />
                  <Menu.ItemTitle>{messages.delete}</Menu.ItemTitle>
                </Menu.Item>
              </>
            )}
          </Menu.Content>
        </Menu.Portal>
      </SafeAreaView>
    </Menu>
  );
}
