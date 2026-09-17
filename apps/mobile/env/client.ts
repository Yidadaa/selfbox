import Constants from "expo-constants";
import { formatConfigLog, loadConfig } from "@/lib/config";

export const config = loadConfig({
  expoExtra: Constants.expoConfig?.extra,
  hostUri: Constants.expoConfig?.hostUri,
  isDev: __DEV__,
  // Expo 仅内联这种静态属性访问，不能遍历或解构 process.env。
  publicEnv: {
    EXPO_PUBLIC_API_BASE_URL: process.env.EXPO_PUBLIC_API_BASE_URL,
    EXPO_PUBLIC_USE_DEV_HOST: process.env.EXPO_PUBLIC_USE_DEV_HOST,
  },
});

if (__DEV__) console.log(formatConfigLog(config));
