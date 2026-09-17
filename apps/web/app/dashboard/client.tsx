"use client";

import dynamic from "next/dynamic";

// HashRouter 及全部 dashboard UI 只在浏览器中执行。
const DashboardApp = dynamic(() => import("@/views/dashboard/app"), {
  ssr: false,
  loading: () => (
    <p role="status" className="p-8 text-sm text-muted-foreground">
      Loading dashboard…
    </p>
  ),
});

export function DashboardClient() {
  return <DashboardApp />;
}

const AuthApp = dynamic(() => import("@/views/dashboard/auth"), {
  ssr: false,
  loading: () => (
    <p role="status" className="p-8 text-sm text-muted-foreground">
      Loading login…
    </p>
  ),
});

export function AuthClient() {
  return <AuthApp />;
}
