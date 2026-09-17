import AsyncStorage from "@react-native-async-storage/async-storage";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { HeroUINativeProvider } from "heroui-native/provider";
import {
  createContext,
  type ReactNode,
  useContext,
  useEffect,
  useState,
} from "react";
import { ActivityIndicator, Text } from "react-native";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { Uniwind } from "uniwind";
import { useStore } from "zustand";
import { config } from "@/env/client";
import { createMobileAuth, type MobileAuth } from "@/lib/auth";
import { resolveHost } from "@/lib/config";
import { createSettingsStore } from "@/lib/settings";
import { createMobileTRPC, TRPCProvider } from "@/lib/trpc";
import { preferencesStore, useAppearance } from "./appearance";
import { Screen } from "./screen";

export const settingsStore = createSettingsStore(AsyncStorage);
export const defaultHost = config.apiBaseUrl;

interface Backend {
  baseURL: string;
  auth: MobileAuth;
}
const BackendContext = createContext<Backend | null>(null);
export const useBackend = () => useContext(BackendContext);

function BackendProvider({
  baseURL,
  children,
}: {
  baseURL: string;
  children: ReactNode;
}) {
  const [backend] = useState(() => ({
    baseURL,
    auth: createMobileAuth(baseURL),
  }));
  return <BackendContext value={backend}>{children}</BackendContext>;
}

// 会话身份变化时由调用方重建，避免不同用户复用查询缓存。
export function QueryProvider({
  backend,
  children,
}: {
  backend: Backend;
  children: ReactNode;
}) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: { queries: { retry: false, staleTime: 30_000 } },
      }),
  );
  const [trpcClient] = useState(() =>
    createMobileTRPC(backend.baseURL, () => backend.auth.getCookie()),
  );
  useEffect(
    () => () => {
      queryClient.clear();
    },
    [queryClient],
  );
  return (
    <QueryClientProvider client={queryClient}>
      <TRPCProvider queryClient={queryClient} trpcClient={trpcClient}>
        {children}
      </TRPCProvider>
    </QueryClientProvider>
  );
}

export function Providers({ children }: { children: ReactNode }) {
  const { messages } = useAppearance();
  const devHost = useStore(settingsStore, (state) => state.devHost);
  const [ready, setReady] = useState(false);
  const [storageError, setStorageError] = useState(false);
  const baseURL = resolveHost(defaultHost, devHost, __DEV__);

  useEffect(() => {
    let active = true;
    const unsubscribe = preferencesStore.subscribe((current, previous) => {
      if (current.theme !== previous.theme) Uniwind.setTheme(current.theme);
    });
    async function hydrate() {
      try {
        await Promise.all([
          settingsStore.persist.rehydrate(),
          preferencesStore.persist.rehydrate(),
        ]);
      } finally {
        if (active) {
          Uniwind.setTheme(preferencesStore.getState().theme);
          setStorageError(
            !settingsStore.persist.hasHydrated() ||
              !preferencesStore.persist.hasHydrated(),
          );
          setReady(true);
        }
      }
    }
    void hydrate();
    return () => {
      active = false;
      unsubscribe();
    };
  }, []);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <HeroUINativeProvider>
          {storageError && (
            <Text
              accessibilityRole="alert"
              className="bg-background px-6 pt-12 text-danger"
            >
              {messages.storageError}
            </Text>
          )}
          {!ready ? (
            <Screen>
              <ActivityIndicator accessibilityLabel={messages.loading} />
            </Screen>
          ) : baseURL ? (
            <BackendProvider key={baseURL} baseURL={baseURL}>
              {children}
            </BackendProvider>
          ) : (
            children
          )}
        </HeroUINativeProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
