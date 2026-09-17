import { BlurView, type BlurViewProps } from "expo-blur";
import { router } from "expo-router";
import type { BottomTabBarProps } from "expo-router/tabs";
import { Surface } from "heroui-native/surface";
import { MessageCircle, Plus, Settings2 } from "lucide-react-native";
import { useEffect, useState } from "react";
import { Keyboard, Pressable, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useAppearance } from "./appearance";

type FloatingTabsProps = BottomTabBarProps & {
  blurTarget: BlurViewProps["blurTarget"];
};

export function FloatingTabs({
  state,
  navigation,
  blurTarget,
}: FloatingTabsProps) {
  const { colors, dark, messages } = useAppearance();
  const insets = useSafeAreaInsets();
  const [keyboardVisible, setKeyboardVisible] = useState(Keyboard.isVisible());
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
  if (keyboardVisible) return null;
  return (
    <View
      pointerEvents="box-none"
      className="absolute inset-x-0 bottom-0 flex-row items-center gap-3 px-7"
      style={{ paddingBottom: Math.max(insets.bottom, 16) }}
    >
      <Surface
        variant="transparent"
        className="h-[66px] shadow-2xl flex-1 flex-row items-center overflow-hidden rounded-full border border-border/60 p-1"
      >
        <BlurView
          pointerEvents="none"
          blurTarget={blurTarget}
          blurMethod="dimezisBlurViewSdk31Plus"
          intensity={90}
          tint={dark ? "dark" : "light"}
          style={StyleSheet.absoluteFill}
        />
        {state.routes.map((route, index) => {
          const selected = state.index === index;
          const Icon = route.name === "index" ? MessageCircle : Settings2;
          const label =
            route.name === "index" ? messages.chats : messages.settings;
          return (
            <Pressable
              key={route.key}
              accessibilityRole="tab"
              accessibilityLabel={label}
              accessibilityState={{ selected }}
              className="h-full flex-1 flex-row items-center justify-center gap-2 rounded-full"
              style={({ pressed }) => ({
                opacity: pressed ? 0.6 : 1,
                backgroundColor: selected ? colors.background : "transparent",
              })}
              onPress={() => {
                const event = navigation.emit({
                  type: "tabPress",
                  target: route.key,
                  canPreventDefault: true,
                });
                if (!selected && !event.defaultPrevented)
                  navigation.navigate(route.name, route.params);
              }}
            >
              <Icon
                size={21}
                color={selected ? colors.accent : colors.muted}
                strokeWidth={selected ? 2.2 : 1.8}
              />
              <Text
                className={`text-sm font-semibold ${selected ? "text-accent" : "text-muted"}`}
              >
                {label}
              </Text>
            </Pressable>
          );
        })}
      </Surface>
      <Surface
        variant="transparent"
        className="overflow-hidden shadow-2xl rounded-full border border-border/60 p-1"
      >
        <BlurView
          pointerEvents="none"
          blurTarget={blurTarget}
          blurMethod="dimezisBlurViewSdk31Plus"
          intensity={90}
          tint={dark ? "dark" : "light"}
          style={StyleSheet.absoluteFill}
        />
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={messages.newChat}
          className="h-[60px] w-[60px] items-center justify-center rounded-full"
          onPress={() => router.push("/new-chat")}
          style={({ pressed }) => ({
            opacity: pressed ? 0.6 : 1,
          })}
        >
          <Plus size={29} strokeWidth={1.8} color={colors.accent} />
        </Pressable>
      </Surface>
    </View>
  );
}
