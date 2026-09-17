import {
  apiBaseUrlSchema,
  EnvSchema,
  type ExpoConfigKey,
  ExpoConfigSchema,
  expoToEnvKeyMap,
  parseConfig,
} from "@/env/schema";

export function normalizeHost(value: string): string {
  const host = apiBaseUrlSchema.parse(value);
  if (!host) {
    throw new Error("Invalid server origin");
  }
  return host;
}

export function resolveHost(
  configured: unknown,
  override: string | null,
  isDev: boolean,
) {
  const value = isDev && override ? override : configured;
  if (typeof value !== "string" || !value) return null;
  try {
    return normalizeHost(value);
  } catch {
    return null;
  }
}

export function sessionStoragePrefix(baseURL: string) {
  // 无损编码 origin，确保不同主机、端口和协议的会话不会串用。
  return `expo-starter.${Array.from(normalizeHost(baseURL), (character) =>
    character.charCodeAt(0).toString(16).padStart(4, "0"),
  ).join("")}`;
}

export function loadDevHost(hostUri: string | null | undefined) {
  try {
    if (!hostUri?.trim()) throw new Error("Missing hostUri");
    const value = hostUri.trim();
    const url = new URL(
      /^[a-z][a-z\d+.-]*:\/\//i.test(value) ? value : `http://${value}`,
    );
    if (
      !url.hostname ||
      url.username ||
      url.password ||
      !["http:", "https:", "exp:", "exps:"].includes(url.protocol)
    ) {
      throw new Error("Invalid hostUri");
    }
    return {
      host: url.hostname,
      apiBaseUrl: normalizeHost(`http://${url.hostname}:3000`),
    };
  } catch {
    throw new Error(
      "[config] Cannot derive the API host from Expo hostUri. Set the server in /dev or disable useDevHost and configure EXPO_PUBLIC_API_BASE_URL.",
    );
  }
}

export interface ConfigInput {
  expoExtra?: unknown;
  publicEnv?: unknown;
  hostUri?: string | null;
  isDev: boolean;
}

export function loadConfig({
  expoExtra = {},
  publicEnv = {},
  hostUri,
  isDev,
}: ConfigInput) {
  const expo = parseConfig(ExpoConfigSchema, expoExtra, "Expo extra");
  const env = parseConfig(EnvSchema, publicEnv, "环境变量");
  const apiBaseUrl = env.EXPO_PUBLIC_API_BASE_URL ?? expo.apiBaseUrl;
  const requestedUseDevHost =
    env.EXPO_PUBLIC_USE_DEV_HOST ?? expo.useDevHost ?? false;
  const config = { apiBaseUrl, useDevHost: isDev && requestedUseDevHost };
  let source: "env" | "expo" | "devHost" | "unset" =
    env.EXPO_PUBLIC_API_BASE_URL !== undefined
      ? "env"
      : expo.apiBaseUrl !== undefined
        ? "expo"
        : "unset";
  let devHostError: string | null = null;
  if (config.useDevHost) {
    try {
      config.apiBaseUrl = loadDevHost(hostUri).apiBaseUrl;
      source = "devHost";
    } catch (error) {
      devHostError =
        error instanceof Error
          ? error.message
          : "[config] Invalid Expo hostUri";
    }
  }
  const rows = (Object.keys(expoToEnvKeyMap) as ExpoConfigKey[]).map((key) => ({
    name: key,
    env: expoToEnvKeyMap[key],
    expo: expo[key] !== undefined,
    environment: env[expoToEnvKeyMap[key]] !== undefined,
    value: config[key],
  }));
  return { ...config, source, devHostError, rows };
}

export function formatConfigLog(config: ReturnType<typeof loadConfig>) {
  const lines = config.rows.map(
    (row) =>
      `${row.name.padEnd(12)} ${row.env.padEnd(28)} ${String(row.expo).padEnd(5)} ${String(row.environment).padEnd(5)} ${String(row.value ?? "(unset)")}`,
  );
  return [
    `[config] loaded from Expo extra and public environment; API source: ${config.source}`,
    `${"Name".padEnd(12)} ${"Env".padEnd(28)} expo  env   value`,
    ...lines,
    ...(config.source === "devHost"
      ? ["[config] Start the API server with pnpm dev:web."]
      : []),
    ...(config.devHostError ? [config.devHostError] : []),
  ].join("\n");
}
