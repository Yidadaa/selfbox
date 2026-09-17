import "server-only";

import { appRouter, createCallerFactory } from "@repo/server/trpc";
import { dehydrate, HydrationBoundary } from "@tanstack/react-query";
import { createTRPCOptionsProxy } from "@trpc/tanstack-react-query";
import { headers } from "next/headers";
import { cache } from "react";
import { createContext } from "./context";
import { makeQueryClient } from "./query-client";

const getContext = cache(async () => createContext(await headers()));
export const getQueryClient = cache(makeQueryClient);

// SSR 直接调用相同的 router，复用鉴权，不经 HTTP 回环。
export const api = createCallerFactory(appRouter)(getContext);
export const trpc = createTRPCOptionsProxy({
  router: appRouter,
  ctx: getContext,
  queryClient: getQueryClient,
});

export function HydrateClient({ children }: { children: React.ReactNode }) {
  return (
    <HydrationBoundary state={dehydrate(getQueryClient())}>
      {children}
    </HydrationBoundary>
  );
}
