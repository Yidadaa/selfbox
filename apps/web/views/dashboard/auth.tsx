"use client";

import { HashRouter, Navigate, Route, Routes } from "react-router";
import { TRPCReactProvider } from "@/lib/trpc/client";
import { LoginPage } from "./login";

export default function AuthApp() {
  return (
    <TRPCReactProvider>
      <HashRouter>
        <Routes>
          <Route path="login" element={<LoginPage key="login" />} />
          <Route path="signup" element={<LoginPage key="signup" isSignUp />} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </HashRouter>
    </TRPCReactProvider>
  );
}
