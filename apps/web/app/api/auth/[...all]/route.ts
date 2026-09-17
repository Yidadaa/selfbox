import { toNextJsHandler } from "better-auth/next-js";
import { getServices } from "@/lib/server";

export const runtime = "nodejs";

export const { GET, POST } = toNextJsHandler((request) =>
  getServices().auth.handler(request),
);
