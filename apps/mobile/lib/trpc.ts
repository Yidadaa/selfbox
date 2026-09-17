import type { AppRouter } from "@repo/server/trpc";
import { createTRPCClient, httpBatchLink } from "@trpc/client";
import { createTRPCContext } from "@trpc/tanstack-react-query";
import superjson from "superjson";
import { normalizeHost } from "./config";

export const { TRPCProvider, useTRPC } = createTRPCContext<AppRouter>();

export function createMobileTRPC(
  baseURL: string,
  getCookie: () => string | Promise<string> = () => "",
) {
  return createTRPCClient<AppRouter>({
    links: [
      httpBatchLink({
        url: `${normalizeHost(baseURL)}/api/trpc`,
        transformer: superjson,
        async headers() {
          const cookie = await getCookie();
          return cookie ? { Cookie: cookie } : {};
        },
        async fetch(input, init) {
          const controller = new AbortController();
          const abort = () => controller.abort();
          const signal = init?.signal;
          if (signal?.aborted) abort();
          signal?.addEventListener("abort", abort);
          const timer = setTimeout(abort, 10_000);
          try {
            return await fetch(input, {
              ...init,
              credentials: "omit",
              signal: controller.signal,
            });
          } finally {
            clearTimeout(timer);
            signal?.removeEventListener("abort", abort);
          }
        },
      }),
    ],
  });
}
