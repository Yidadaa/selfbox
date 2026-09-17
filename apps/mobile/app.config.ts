import type { ConfigContext, ExpoConfig } from "expo/config";
import { createMobileEnv, MOBILE_SCHEME } from "./env";

export default ({ config }: ConfigContext): ExpoConfig => {
  const env = createMobileEnv({
    BASE_URL: process.env.BASE_URL,
    VERCEL_URL: process.env.VERCEL_URL,
    EXPO_PUBLIC_API_BASE_URL: process.env.EXPO_PUBLIC_API_BASE_URL,
    EXPO_PUBLIC_USE_DEV_HOST: process.env.EXPO_PUBLIC_USE_DEV_HOST,
  });
  return {
    ...config,
    name: "Expo Starter",
    slug: "expo-starter",
    scheme: MOBILE_SCHEME,
    // extra 会写入客户端，只放公开配置。
    extra: {
      ...config.extra,
      ...(env.BASE_URL ? { apiBaseUrl: env.BASE_URL } : {}),
    },
  };
};
