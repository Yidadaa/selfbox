import type { BlurViewProps } from "expo-blur";
import { Button } from "heroui-native/button";
import { ArrowUp, Camera, Check, Pencil, X } from "lucide-react-native";
import { type RefObject, useState } from "react";
import {
  ActivityIndicator,
  Image,
  Text,
  TextInput,
  useWindowDimensions,
  View,
} from "react-native";
import { useAppearance } from "@/components/appearance";
import { messageText } from "@/db/payload";
import type { Message } from "@/db/schema";
import { Glass } from "./glass";

export function Composer({
  blurTarget,
  inputRef,
  text,
  imageUri,
  editing,
  busy,
  canSend,
  canRemoveImage,
  availableHeight,
  onChangeText,
  onPickImage,
  onRemoveImage,
  onCancelEdit,
  onSend,
}: {
  blurTarget: BlurViewProps["blurTarget"];
  inputRef: RefObject<TextInput | null>;
  text: string;
  imageUri?: string;
  editing: Message | null;
  busy: boolean;
  canSend: boolean;
  canRemoveImage: boolean;
  availableHeight: number;
  onChangeText: (text: string) => void;
  onPickImage: () => void;
  onRemoveImage: () => void;
  onCancelEdit: () => void;
  onSend: () => void;
}) {
  const { colors, messages, dark } = useAppearance();
  const { height, fontScale } = useWindowDimensions();
  const [contentHeight, setContentHeight] = useState(44);
  const [editHeaderHeight, setEditHeaderHeight] = useState(0);
  const minInputHeight = Math.max(44, Math.ceil(24 * fontScale + 20));
  const previewHeight = imageUri ? Math.min(152, availableHeight * 0.3) : 0;
  // 留出照片、编辑栏和一小段消息区域；横屏或键盘展开时仍可操作。
  const maxInputHeight = Math.max(
    minInputHeight,
    Math.min(
      height / 2,
      availableHeight - previewHeight - (editing ? editHeaderHeight : 0) - 80,
    ),
  );
  const inputHeight = Math.min(
    maxInputHeight,
    Math.max(minInputHeight, text ? contentHeight : minInputHeight),
  );

  return (
    <View className="shrink-0 px-4 pb-2 pt-2">
      <Glass
        blurTarget={blurTarget}
        className="rounded-[28px] border"
        style={{ borderColor: editing ? colors.accent : colors.border }}
      >
        {imageUri && (
          <View
            className="flex-row items-start gap-1 pl-3 pt-2"
            style={{ height: previewHeight }}
          >
            <View
              className="rounded-xl border border-border bg-surface p-1.5 pb-3"
              style={{
                width: previewHeight * 0.88,
                height: previewHeight - 22,
                transform: [{ rotate: "-3deg" }],
                boxShadow: dark
                  ? "0 6px 16px rgba(0, 0, 0, 0.28), 0 1px 3px rgba(0, 0, 0, 0.2)"
                  : "0 6px 16px rgba(24, 32, 44, 0.1), 0 1px 3px rgba(24, 32, 44, 0.08)",
              }}
            >
              <View className="flex-1 overflow-hidden rounded-lg bg-elevated">
                <Image
                  accessibilityLabel={messages.image}
                  source={{ uri: imageUri }}
                  resizeMode="cover"
                  className="h-full w-full"
                />
                <View
                  pointerEvents="none"
                  className="absolute inset-0 rounded-lg"
                  style={{
                    borderWidth: 1,
                    borderColor: "rgba(255, 255, 255, 0.18)",
                    borderBottomColor: "rgba(0, 0, 0, 0.08)",
                  }}
                />
              </View>
            </View>
            {canRemoveImage && (
              <Button
                accessibilityLabel={messages.removeImage}
                isIconOnly
                variant="ghost"
                className="h-11 w-11 rounded-full"
                isDisabled={busy}
                onPress={onRemoveImage}
              >
                <X size={18} color={colors.muted} strokeWidth={1.8} />
              </Button>
            )}
          </View>
        )}
        <View className="p-1.5">
          {editing && (
            <View
              className="mx-2 mb-1 flex-row items-center gap-3 border-b border-border pb-2 pt-1"
              onLayout={({ nativeEvent }) =>
                setEditHeaderHeight(nativeEvent.layout.height + 4)
              }
            >
              <View className="w-0.5 self-stretch rounded-full bg-accent" />
              <View className="flex-1 gap-1 py-1">
                <View className="flex-row items-center gap-1.5">
                  <Pencil size={12} color={colors.accent} strokeWidth={1.8} />
                  <Text className="text-xs font-semibold text-accent">
                    {messages.editing}
                  </Text>
                </View>
                <Text numberOfLines={1} className="text-xs text-muted">
                  {messageText(editing.payload) || messages.image}
                </Text>
              </View>
              <Button
                variant="ghost"
                size="sm"
                className="min-h-11 rounded-full px-2"
                isDisabled={busy}
                onPress={onCancelEdit}
              >
                <Button.Label className="text-sm text-muted">
                  {messages.cancel}
                </Button.Label>
              </Button>
            </View>
          )}
          <View className="flex-row items-end gap-1">
            <TextInput
              ref={inputRef}
              accessibilityLabel={
                editing ? messages.editing : messages.messagePlaceholder
              }
              placeholder={
                imageUri ? messages.imageCaption : messages.messagePlaceholder
              }
              placeholderTextColor={colors.muted}
              selectionColor={colors.accent}
              keyboardAppearance={dark ? "dark" : "light"}
              multiline
              maxLength={50_000}
              value={text}
              onChangeText={onChangeText}
              onContentSizeChange={({ nativeEvent }) =>
                setContentHeight(Math.ceil(nativeEvent.contentSize.height))
              }
              scrollEnabled={contentHeight > maxInputHeight}
              editable={!busy}
              underlineColorAndroid="transparent"
              className="flex-1 px-3 text-base leading-6 text-foreground"
              style={{
                height: inputHeight,
                paddingVertical: 10,
                textAlignVertical: "top",
                includeFontPadding: false,
              }}
            />
            <Button
              accessibilityLabel={messages.addImage}
              isIconOnly
              variant="ghost"
              className="h-11 w-11 rounded-full"
              onPress={onPickImage}
              isDisabled={busy}
            >
              <Camera size={22} color={colors.muted} strokeWidth={1.8} />
            </Button>
            <Button
              accessibilityLabel={
                editing ? messages.saveMessage : messages.send
              }
              isIconOnly
              className="h-11 w-11 rounded-full"
              isDisabled={!canSend}
              onPress={onSend}
            >
              {busy ? (
                <ActivityIndicator
                  size="small"
                  color={colors.accentForeground}
                />
              ) : editing ? (
                <Check
                  size={21}
                  color={colors.accentForeground}
                  strokeWidth={2}
                />
              ) : (
                <ArrowUp
                  size={21}
                  color={colors.accentForeground}
                  strokeWidth={2}
                />
              )}
            </Button>
          </View>
        </View>
      </Glass>
    </View>
  );
}
