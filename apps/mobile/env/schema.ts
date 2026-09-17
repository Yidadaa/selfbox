import { z } from "zod";

export const MOBILE_SCHEME = "selfbox";

const optionalBoolean = z.preprocess((value) => {
  if (typeof value !== "string") return value;
  const normalized = value.trim().toLowerCase();
  if (normalized === "") return undefined;
  if (normalized === "true" || normalized === "1") return true;
  if (normalized === "false" || normalized === "0") return false;
  return value;
}, z.boolean().optional());

export const apiBaseUrlSchema = z.preprocess(
  (value) => (typeof value === "string" ? value.trim() || undefined : value),
  z
    .url()
    .refine((value) => {
      const url = new URL(value);
      return (
        ["http:", "https:"].includes(url.protocol) &&
        !url.username &&
        !url.password &&
        url.pathname === "/" &&
        !url.search &&
        !url.hash
      );
    }, "Use an HTTP(S) origin without a path, query, or credentials")
    .transform((value) => new URL(value).origin)
    .optional(),
);

export const ExpoConfigSchema = z.object({
  apiBaseUrl: apiBaseUrlSchema,
  useDevHost: optionalBoolean,
});

export type ExpoConfig = z.output<typeof ExpoConfigSchema>;
export type ExpoConfigKey = keyof ExpoConfig;

export const expoToEnvKeyMap = {
  apiBaseUrl: "EXPO_PUBLIC_API_BASE_URL",
  useDevHost: "EXPO_PUBLIC_USE_DEV_HOST",
} as const satisfies Record<ExpoConfigKey, `EXPO_PUBLIC_${string}`>;

// 配置和环境变量共用字段 schema；读取 process.env 时仍需使用静态属性。
export const publicEnvShape = {
  [expoToEnvKeyMap.apiBaseUrl]: ExpoConfigSchema.shape.apiBaseUrl,
  [expoToEnvKeyMap.useDevHost]: ExpoConfigSchema.shape.useDevHost,
};
export const EnvSchema = z.object(publicEnvShape);

export function parseConfig<T extends z.ZodType>(
  schema: T,
  value: unknown,
  name: string,
): z.output<T> {
  const result = schema.safeParse(value);
  if (result.success) return result.data;
  const details = result.error.issues
    .map(
      (issue) =>
        `- ${issue.path.length ? issue.path.join(".") : "(root)"}: ${issue.message}`,
    )
    .join("\n");
  throw new Error(`[config] ${name} 解析失败:\n${details}`);
}
