"use client";

import { createAuthClient } from "better-auth/react";

// 同源 /api/auth，无需把服务端 URL 或密钥暴露给浏览器。
export const authClient = createAuthClient();
