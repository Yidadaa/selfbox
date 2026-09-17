"use client";

import { Button } from "@repo/ui/components/button";
import { HashRouter, Navigate, Route, Routes } from "react-router";
import { authClient } from "@/lib/auth";
import { TRPCReactProvider } from "@/lib/trpc/client";
import { ActivityPage } from "./activity";
import AuthApp from "./auth";
import { DashboardNotFound } from "./not-found";
import { OverviewPage } from "./overview";
import { DashboardShell } from "./shell";

export default function DashboardApp() {
  const { data: session, isPending, error, refetch } = authClient.useSession();

  // 客户端再次校验，处理会话过期及其他标签页退出；校验完成前不挂载 dashboard。
  if (isPending) {
    return (
      <p role="status" className="p-8 text-sm text-muted-foreground">
        Checking your session…
      </p>
    );
  }
  if (error) {
    return (
      <div className="flex min-h-svh flex-col items-center justify-center gap-4 p-6">
        <p role="alert">Unable to verify your session. Please try again.</p>
        <Button onClick={() => refetch()}>Try again</Button>
      </div>
    );
  }
  if (!session) return <AuthApp />;

  return (
    <TRPCReactProvider>
      <HashRouter>
        <Routes>
          <Route path="login" element={<Navigate to="/" replace />} />
          <Route path="signup" element={<Navigate to="/" replace />} />
          <Route element={<DashboardShell />}>
            <Route index element={<OverviewPage />} />
            <Route path="activity" element={<ActivityPage />} />
            <Route path="*" element={<DashboardNotFound />} />
          </Route>
        </Routes>
      </HashRouter>
    </TRPCReactProvider>
  );
}
