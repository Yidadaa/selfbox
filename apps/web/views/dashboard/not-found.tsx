import { Link } from "react-router";

export function DashboardNotFound() {
  return (
    <section aria-labelledby="not-found-heading">
      <h1
        id="not-found-heading"
        className="text-3xl font-medium tracking-tight"
      >
        Page not found
      </h1>
      <p className="mt-3 text-base leading-7 text-muted-foreground">
        This dashboard page doesn’t exist.
      </p>
      <Link
        to="/"
        className="mt-6 inline-block text-sm underline underline-offset-4"
      >
        Back to overview
      </Link>
    </section>
  );
}
