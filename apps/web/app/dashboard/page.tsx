import type { Metadata } from "next";
import { headers } from "next/headers";
import { getServices } from "@/lib/server";
import { AuthClient, DashboardClient } from "./client";

export const metadata: Metadata = {
  title: "Dashboard — Expo Starter",
  description: "Your Expo Starter dashboard.",
  robots: { index: false, follow: false },
};

export default async function DashboardPage() {
  const session = await getServices().auth.api.getSession({
    headers: await headers(),
    query: { disableCookieCache: true },
  });

  // Hash 路径不随请求发送；未登录时只加载公开认证界面，避免同路由重定向循环。
  if (!session) return <AuthClient />;

  return <DashboardClient />;
}
