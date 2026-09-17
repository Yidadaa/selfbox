export function OverviewPage() {
  return (
    <section aria-labelledby="overview-heading">
      <h1 id="overview-heading" className="text-3xl font-medium tracking-tight">
        Overview
      </h1>
      <p className="mt-3 text-base leading-7 text-muted-foreground">
        A place for a fuller picture of your day.
      </p>
      <div className="mt-8 rounded-lg border p-6">
        <h2 className="text-base font-medium">Thoughtfully in the making</h2>
        <p className="mt-2 text-sm leading-6 text-muted-foreground">
          We’re building your Expo Starter dashboard. There’s nothing to set up
          just yet.
        </p>
      </div>
    </section>
  );
}
