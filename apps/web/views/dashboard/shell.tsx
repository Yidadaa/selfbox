import Link from "next/link";
import { NavLink, Outlet } from "react-router";

const navigation = [
  { to: "/", label: "Overview" },
  { to: "/activity", label: "Activity" },
];

export function DashboardShell() {
  return (
    <div className="mx-auto min-h-svh max-w-5xl border-x">
      <header className="flex flex-wrap items-center justify-between gap-4 border-b px-6 py-6 sm:px-10">
        <Link
          href="/"
          aria-label="Expo Starter home"
          className="text-3xl font-semibold tracking-[-0.075em]"
        >
          expo-starter.
        </Link>
        <span className="text-sm text-muted-foreground">Dashboard</span>
      </header>
      <div className="grid sm:grid-cols-[12rem_1fr]">
        <nav
          aria-label="Dashboard navigation"
          className="flex gap-2 border-b p-4 sm:min-h-[calc(100svh-5.5rem)] sm:flex-col sm:border-r sm:border-b-0"
        >
          {navigation.map(({ to, label }) => (
            <NavLink
              key={to}
              to={to}
              end
              className={({ isActive }) =>
                `rounded-md px-4 py-3 text-sm transition-colors ${isActive ? "bg-muted font-medium text-foreground" : "text-muted-foreground hover:bg-muted/50 hover:text-foreground"}`
              }
            >
              {label}
            </NavLink>
          ))}
        </nav>
        <main className="min-w-0 px-6 py-10 sm:px-10">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
