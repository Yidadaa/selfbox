import "../global.css";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { ActivityIndicator } from "react-native";
import { Providers, QueryProvider, useBackend } from "@/components/providers";
import { Screen } from "@/components/screen";
import { messages } from "@/i18n/en";

function Routes({ signedIn }: { signedIn: boolean }) {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Protected guard={signedIn}>
        <Stack.Screen name="index" />
      </Stack.Protected>
      <Stack.Protected guard={!signedIn}>
        <Stack.Screen name="login" />
      </Stack.Protected>
      <Stack.Protected guard={__DEV__}>
        <Stack.Screen name="dev" />
      </Stack.Protected>
    </Stack>
  );
}

function SessionRoutes({
  backend,
}: {
  backend: NonNullable<ReturnType<typeof useBackend>>;
}) {
  const { data: session, isPending } = backend.auth.useSession();
  if (isPending)
    return (
      <Screen>
        <ActivityIndicator accessibilityLabel={messages.loading} />
      </Screen>
    );
  return (
    <QueryProvider key={session?.user.id ?? "anonymous"} backend={backend}>
      <Routes signedIn={!!session} />
    </QueryProvider>
  );
}

function Navigation() {
  const backend = useBackend();
  return backend ? (
    <SessionRoutes backend={backend} />
  ) : (
    <Routes signedIn={false} />
  );
}

export default function RootLayout() {
  return (
    <Providers>
      <StatusBar style="auto" />
      <Navigation />
    </Providers>
  );
}
