import { BlurTargetView } from "expo-blur";
import { Tabs } from "expo-router";
import { useRef } from "react";
import type { View } from "react-native";
import { FloatingTabs } from "@/components/tabs";

export default function TabLayout() {
  const chatsTarget = useRef<View>(null);
  const settingsTarget = useRef<View>(null);

  return (
    <Tabs
      screenOptions={{ headerShown: false, tabBarHideOnKeyboard: true }}
      screenLayout={({ children, route }) => (
        <BlurTargetView
          ref={route.name === "index" ? chatsTarget : settingsTarget}
          style={{ flex: 1 }}
        >
          {children}
        </BlurTargetView>
      )}
      tabBar={(props) => (
        <FloatingTabs
          {...props}
          blurTarget={
            props.state.routes[props.state.index]?.name === "index"
              ? chatsTarget
              : settingsTarget
          }
        />
      )}
    >
      <Tabs.Screen name="index" />
      <Tabs.Screen name="settings" />
    </Tabs>
  );
}
