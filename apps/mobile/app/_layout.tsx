import "../global.css";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { useAppearance } from "@/components/appearance";
import { DatabaseProvider } from "@/components/database";
import { Providers } from "@/components/providers";

function Navigation() {
  const { colors, dark } = useAppearance();
  return (
    <DatabaseProvider>
      <StatusBar style={dark ? "light" : "dark"} />
      <Stack
        screenOptions={{
          headerShown: false,
          contentStyle: { backgroundColor: colors.background },
        }}
      >
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="chat/[id]" />
        <Stack.Screen name="new-chat" options={{ presentation: "modal" }} />
        <Stack.Screen name="account" />
        <Stack.Protected guard={__DEV__}>
          <Stack.Screen name="dev" />
        </Stack.Protected>
      </Stack>
    </DatabaseProvider>
  );
}

export default function RootLayout() {
  return (
    <Providers>
      <Navigation />
    </Providers>
  );
}
