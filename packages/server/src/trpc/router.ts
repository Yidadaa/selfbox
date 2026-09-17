import { createTRPCRouter, publicProcedure } from "./init";
import { userRouter } from "./routers/user";

export const appRouter = createTRPCRouter({
  health: publicProcedure.query(() => ({ status: "ok" as const })),
  user: userRouter,
});

export type AppRouter = typeof appRouter;
