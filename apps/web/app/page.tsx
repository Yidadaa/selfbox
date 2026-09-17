import Link from "next/link";

const capabilities = [
  {
    number: "01",
    title: "Web application",
    description:
      "A Next.js App Router application with authentication, dashboard routing, and a production-ready foundation.",
  },
  {
    number: "02",
    title: "Native mobile",
    description:
      "An Expo Router app with shared configuration, secure sessions, and a clear path to native development builds.",
  },
  {
    number: "03",
    title: "Typed server stack",
    description:
      "Shared tRPC, Better Auth, Drizzle, and database modules keep the contract between your clients and server explicit.",
  },
];

export default function Home() {
  return (
    <div
      id="top"
      className="mx-auto min-h-svh max-w-5xl border-x border-border"
    >
      <a
        href="#main"
        className="sr-only z-50 bg-background p-4 focus:not-sr-only focus:fixed focus:top-4 focus:left-4"
      >
        Skip to content
      </a>

      <header className="flex min-h-22 flex-wrap items-center justify-between gap-x-8 gap-y-3 border-b px-6 py-5 sm:px-12">
        <a
          href="#top"
          aria-label="Expo Starter home"
          className="text-3xl font-semibold tracking-[-0.075em]"
        >
          expo-starter<span className="text-muted-foreground">.</span>
        </a>
        <nav
          aria-label="Main navigation"
          className="flex flex-wrap items-center gap-x-6 gap-y-3 text-sm sm:gap-x-8"
        >
          <a className="nav-link" href="#capabilities">
            Capabilities
          </a>
          <a className="nav-link" href="#workflow">
            Workflow
          </a>
          <Link
            href="/dashboard"
            prefetch={false}
            className="nav-link border-l pl-6 sm:pl-8"
          >
            Dashboard
          </Link>
        </nav>
      </header>

      <main id="main">
        <section
          aria-labelledby="hero-heading"
          className="px-6 pt-16 pb-12 sm:px-12 sm:pt-24 sm:pb-16"
        >
          <p className="mb-7 font-mono text-xs tracking-[0.12em] text-muted-foreground uppercase">
            A full-stack foundation for your next idea.
          </p>
          <h1
            id="hero-heading"
            className="max-w-3xl text-[clamp(2.75rem,6.7vw,4.75rem)] leading-[1.06] font-medium tracking-[-0.065em] text-balance"
          >
            Build your product.
            <br />
            Keep the stack
            <br />
            <span className="text-muted-foreground">in one place.</span>
          </h1>
          <div className="mt-9 flex flex-col justify-between gap-7 sm:flex-row sm:items-end">
            <p className="max-w-lg text-base leading-7 text-muted-foreground sm:text-lg sm:leading-8">
              Expo Starter brings a web app, Expo mobile app, shared UI, typed
              server modules, authentication, and database tooling together in
              one practical monorepo.
            </p>
            <a
              href="#capabilities"
              className="nav-link shrink-0 self-start border-b border-foreground pb-1 text-sm sm:self-auto"
            >
              See what is included{" "}
              <span aria-hidden="true" className="ml-3">
                ↗
              </span>
            </a>
          </div>
        </section>

        <section
          id="capabilities"
          aria-labelledby="capabilities-heading"
          className="grid scroll-mt-8 gap-8 border-b px-6 py-16 sm:grid-cols-[1fr_1.2fr] sm:gap-16 sm:px-12 sm:py-20"
        >
          <div>
            <p className="mb-5 font-mono text-xs tracking-[0.1em] text-muted-foreground uppercase">
              What is included
            </p>
            <h2
              id="capabilities-heading"
              className="text-4xl font-medium tracking-[-0.05em]"
            >
              Everything you need to begin
            </h2>
          </div>
          <div className="space-y-5 text-base leading-7 text-muted-foreground">
            <p className="text-xl leading-8 tracking-[-0.025em] text-foreground">
              One repository.
              <br />A clear starting point.
            </p>
            <p>
              Use the existing applications as a starting point for a product
              that needs a polished web surface, a native mobile client, and a
              shared backend contract.
            </p>
            <p>
              The repository is ready for your domain logic, with clear package
              boundaries and commands for development, testing, linting, and
              type checking.
            </p>
          </div>
        </section>

        <section
          id="workflow"
          aria-labelledby="workflow-heading"
          className="scroll-mt-8 px-6 py-16 sm:px-12 sm:py-20"
        >
          <p className="mb-5 font-mono text-xs tracking-[0.1em] text-muted-foreground uppercase">
            A focused workflow
          </p>
          <h2
            id="workflow-heading"
            className="max-w-xl text-3xl leading-tight font-medium tracking-[-0.045em] sm:text-4xl"
          >
            Keep product work moving.
            <br />
            <span className="text-muted-foreground">
              Extend the parts that matter.
            </span>
          </h2>
          <div className="mt-12 grid gap-8 sm:grid-cols-3 sm:gap-7">
            {capabilities.map((capability) => (
              <article key={capability.number} className="border-t pt-5">
                <span className="font-mono text-xs text-muted-foreground">
                  {capability.number}
                </span>
                <h3 className="mt-5 mb-3 text-lg font-medium tracking-[-0.025em]">
                  {capability.title}
                </h3>
                <p className="text-base leading-7 text-muted-foreground">
                  {capability.description}
                </p>
              </article>
            ))}
          </div>
        </section>

        <section
          aria-labelledby="closing-heading"
          className="border-t bg-muted/40 px-6 py-14 sm:px-12 sm:py-16"
        >
          <p className="mb-5 font-mono text-xs tracking-[0.1em] text-muted-foreground uppercase">
            Ready for your next build
          </p>
          <h2
            id="closing-heading"
            className="text-3xl leading-tight font-medium tracking-[-0.045em] sm:text-4xl"
          >
            Start with a working full-stack template.
          </h2>
          <p className="mt-4 max-w-xl text-base leading-7 text-muted-foreground">
            We’re building Expo Starter as a dependable base for ideas that
            deserve a clean path from first screen to production.
          </p>
        </section>
      </main>

      <footer className="flex flex-wrap items-center justify-between gap-5 border-t px-6 py-7 text-xs text-muted-foreground sm:px-12">
        <p>© {new Date().getFullYear()} Expo Starter</p>
        <p>Build clearly. Ship confidently.</p>
      </footer>
    </div>
  );
}
