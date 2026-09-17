const { createEnv } = require("@t3-oss/env-nextjs");
const {
  apiBaseUrlSchema,
  publicEnvShape,
  MOBILE_SCHEME,
} = require("./env/schema.ts");

/** @param {{ BASE_URL?: string; VERCEL_URL?: string; EXPO_PUBLIC_API_BASE_URL?: string; EXPO_PUBLIC_USE_DEV_HOST?: string }} runtime */
function createMobileEnv(runtime) {
  return createEnv({
    server: {
      BASE_URL: apiBaseUrlSchema,
    },
    shared: publicEnvShape,
    runtimeEnv: {
      BASE_URL:
        runtime.BASE_URL ||
        (runtime.VERCEL_URL ? `https://${runtime.VERCEL_URL}` : undefined),
      EXPO_PUBLIC_API_BASE_URL: runtime.EXPO_PUBLIC_API_BASE_URL,
      EXPO_PUBLIC_USE_DEV_HOST: runtime.EXPO_PUBLIC_USE_DEV_HOST,
    },
    emptyStringAsUndefined: true,
  });
}

module.exports = { createMobileEnv, MOBILE_SCHEME };
