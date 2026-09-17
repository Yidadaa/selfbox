import { expoClient } from "@better-auth/expo/client";
import { createAuthClient } from "better-auth/react";
import * as SecureStore from "expo-secure-store";
import { MOBILE_SCHEME } from "@/env/schema";
import { normalizeHost, sessionStoragePrefix } from "./config";

export function createMobileAuth(baseURL: string) {
  return createAuthClient({
    baseURL: normalizeHost(baseURL),
    fetchOptions: { timeout: 10_000 },
    plugins: [
      expoClient({
        scheme: MOBILE_SCHEME,
        storagePrefix: sessionStoragePrefix(baseURL),
        storage: SecureStore,
        disableCache: true,
      }),
    ],
  });
}

export type MobileAuth = ReturnType<typeof createMobileAuth>;
