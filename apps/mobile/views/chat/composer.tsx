import type { BlurViewProps } from "expo-blur";
import { Button } from "heroui-native/button";
import { ArrowUp, Camera, Check, Pencil, X, XIcon } from "lucide-react-native";
import { type RefObject, useState } from "react";
import {
  ActivityIndicator,
  Image,
  ScrollView,
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
  imageUris,
  editing,
  busy,
  canSend,
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
  imageUris: string[];
  editing: Message | null;
  busy: boolean;
  canSend: boolean;
  availableHeight: number;
  onChangeText: (text: string) => void;
  onPickImage: () => void;
  onRemoveImage: (index: number) => void;
  onCancelEdit: () => void;
  onSend: () => void;
}) {
  const { colors, messages, dark } = useAppearance();
  const { height, fontScale } = useWindowDimensions();
  const [contentHeight, setContentHeight] = useState(44);
  const [editHeaderHeight, setEditHeaderHeight] = useState(0);
  const minInputHeight = Math.max(44, Math.ceil(24 * fontScale + 20));
  const previewHeight = imageUris.length
    ? Math.max(64, Math.min(100, availableHeight * 0.3))
    : 0;
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
        {imageUris.length > 0 && (
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
            contentContainerStyle={{
              gap: 8,
              paddingHorizontal: 12,
              paddingTop: 8,
            }}
            style={{ height: previewHeight, flexGrow: 0 }}
          >
            {imageUris.map((uri, index) => (
              <View
                key={uri}
                className="overflow-hidden rounded-xl border border-border bg-background"
                style={{
                  width: previewHeight - 12,
                  height: previewHeight - 12,
                }}
              >
                <Image
                  accessibilityLabel={`${messages.image} ${index + 1}/${imageUris.length}`}
                  source={{ uri }}
                  resizeMode="cover"
                  className="h-full w-full rounded-lg"
                />
                <Button
                  accessibilityLabel={`${messages.removeImage} ${index + 1}`}
                  isIconOnly
                  variant="ghost"
                  className="absolute right-0 top-0 opacity-80"
                  isDisabled={busy}
                  size="sm"
                  onPress={() => onRemoveImage(index)}
                >
                  <XIcon color={colors.background} size={14} />
                </Button>
              </View>
            ))}
          </ScrollView>
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
                imageUris.length
                  ? messages.imageCaption
                  : messages.messagePlaceholder
              }
              placeholderTextColor={colors.border}
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
              className="h-9 mb-1 mr-1 w-9 rounded-full"
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
                  size={18}
                  color={colors.accentForeground}
                  strokeWidth={2}
                />
              ) : (
                <ArrowUp
                  size={18}
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
