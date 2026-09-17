"use client";

import type { AppRouter } from "@repo/server/trpc";
import { type QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { createTRPCClient, httpBatchLink } from "@trpc/client";
import { createTRPCContext } from "@trpc/tanstack-react-query";
import { useState } from "react";
import superjson from "superjson";
import { makeQueryClient } from "./query-client";

export const { TRPCProvider, useTRPC, useTRPCClient } =
  createTRPCContext<AppRouter>();

let browserQueryClient: QueryClient | undefined;

function getQueryClient() {
  if (typeof window === "undefined") return makeQueryClient();
  browserQueryClient ??= makeQueryClient();
  return browserQueryClient;
}

function getTRPCUrl(serverUrl?: string) {
  if (typeof window !== "undefined") return "/api/trpc";
  if (serverUrl) return serverUrl;
  throw new Error(
    "TRPCReactProvider requires serverUrl when rendered on the server.",
  );
}

export function TRPCReactProvider({
  children,
  serverUrl,
}: {
  children: React.ReactNode;
  serverUrl?: string;
}) {
  const queryClient = getQueryClient();
  const [trpcClient] = useState(() =>
    createTRPCClient<AppRouter>({
      links: [
        httpBatchLink({
          url: getTRPCUrl(serverUrl),
          transformer: superjson,
        }),
      ],
    }),
  );

  return (
    <QueryClientProvider client={queryClient}>
      <TRPCProvider trpcClient={trpcClient} queryClient={queryClient}>
        {children}
      </TRPCProvider>
    </QueryClientProvider>
  );
}
