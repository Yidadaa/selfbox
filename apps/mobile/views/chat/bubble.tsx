import { useMenu } from "heroui-native/menu";
import { ImageOff, Pin } from "lucide-react-native";
import { memo, useMemo, useRef, useState } from "react";
import {
  Image,
  Pressable,
  Text,
  useWindowDimensions,
  View,
} from "react-native";
import { useMarkdown } from "react-native-marked";
import Svg, { Path } from "react-native-svg";
import { useAppearance } from "@/components/appearance";
import type { Message } from "@/db/schema";
import { formatTime } from "@/i18n";
import { attachmentUri } from "@/lib/attachments";

function MarkdownText({ text, color }: { text: string; color: string }) {
  const { dark, colors } = useAppearance();
  const options = useMemo(
    () => ({
      colorScheme: dark ? ("dark" as const) : ("light" as const),
      selectable: false,
      theme: {
        colors: {
          text: color,
          link: color,
          border: colors.border,
          code: colors.markdownCode,
        },
      },
      styles: {
        paragraph: { paddingVertical: 2 },
        text: { fontSize: 16, lineHeight: 23 },
        link: { textDecorationLine: "underline" as const },
        h1: { fontSize: 25, lineHeight: 31 },
        h2: { fontSize: 22, lineHeight: 28 },
        h3: { fontSize: 19, lineHeight: 25 },
        code: { minWidth: 0, padding: 10, borderRadius: 10 },
        codeText: { fontFamily: "monospace", fontSize: 13, lineHeight: 20 },
      },
    }),
    [color, dark, colors.border, colors.markdownCode],
  );
  const nodes = useMarkdown(text, options);
  return <View style={{ flexShrink: 1 }}>{nodes}</View>;
}

export const MessageBubble = memo(function MessageBubble({
  message,
  onLongPress,
}: {
  message: Message;
  onLongPress: () => void;
}) {
  const { colors, bubble, bubbleText, language, messages } = useAppearance();
  const { setTriggerPosition } = useMenu();
  const { width } = useWindowDimensions();
  const own = message.role === "user";
  const background = own ? bubble : colors.incoming;
  const foreground = own ? bubbleText : colors.text;
  const [imageFailed, setImageFailed] = useState(false);
  const target = useRef<View>(null);
  const imageWidth = Math.min(width * 0.65, 280);

  function openMenu(pageX: number, pageY: number) {
    // 使用屏幕触点作为零尺寸锚点，避免菜单按整块气泡定位。
    setTriggerPosition({ pageX, pageY, width: 0, height: 0 });
    onLongPress();
  }

  return (
    <View
      className="my-1.5 px-5"
      style={{ alignItems: own ? "flex-end" : "flex-start" }}
    >
      <Pressable
        ref={target}
        onLongPress={({ nativeEvent: { pageX, pageY } }) => {
          openMenu(pageX, pageY);
        }}
        delayLongPress={350}
        accessibilityHint={messages.messageActions}
        accessibilityActions={[
          { name: "longpress", label: messages.messageActions },
        ]}
        onAccessibilityAction={(event) => {
          if (event.nativeEvent.actionName === "longpress") {
            target.current?.measure((_x, _y, width, height, pageX, pageY) => {
              openMenu(pageX + width / 2, pageY + height / 2);
            });
          }
        }}
        style={{ maxWidth: "84%", minWidth: 44 }}
      >
        <Svg
          width={20}
          height={22}
          viewBox="0 0 20 22"
          style={{
            position: "absolute",
            bottom: 0,
            ...(own
              ? { right: -6 }
              : { left: -6, transform: [{ scaleX: -1 }] }),
          }}
        >
          <Path
            d="M0 0H12V7C12 14 14 18 20 21C11 23 3 18 0 12Z"
            fill={background}
          />
        </Svg>
        <View
          style={{
            backgroundColor: background,
            borderRadius: 21,
            paddingHorizontal: message.payload.type === "image" ? 5 : 14,
            paddingVertical: message.payload.type === "image" ? 5 : 9,
            overflow: "hidden",
          }}
        >
          {message.payload.type === "text" ? (
            <MarkdownText text={message.payload.text} color={foreground} />
          ) : (
            <>
              {imageFailed ? (
                <View
                  className="items-center justify-center gap-2 p-5"
                  style={{ width: imageWidth, height: 150 }}
                >
                  <ImageOff color={foreground} size={26} />
                  <Text style={{ color: foreground }}>
                    {messages.imageUnavailable}
                  </Text>
                </View>
              ) : (
                <Image
                  accessibilityLabel={messages.image}
                  source={{ uri: attachmentUri(message.payload.image) }}
                  onError={() => setImageFailed(true)}
                  style={{
                    width: imageWidth,
                    height: Math.min(
                      340,
                      Math.max(
                        110,
                        (imageWidth * message.payload.image.height) /
                          message.payload.image.width,
                      ),
                    ),
                    borderRadius: 17,
                  }}
                  resizeMode="cover"
                />
              )}
              {!!message.payload.caption && (
                <View className="px-2.5 pb-1.5 pt-2">
                  <MarkdownText
                    text={message.payload.caption}
                    color={foreground}
                  />
                </View>
              )}
            </>
          )}
        </View>
      </Pressable>
      <View className="mt-1 flex-row items-center gap-1.5 px-1">
        <Text className="text-[10px] text-muted">
          {formatTime(message.createdAt, language)}
          {message.updatedAt > message.createdAt ? ` · ${messages.edited}` : ""}
        </Text>
        {message.pinnedAt !== null && <Pin size={10} color={colors.accent} />}
      </View>
    </View>
  );
});
