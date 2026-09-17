export function ActivityPage() {
  return (
    <section aria-labelledby="activity-heading">
      <h1 id="activity-heading" className="text-3xl font-medium tracking-tight">
        Activity
      </h1>
      <p className="mt-3 text-base leading-7 text-muted-foreground">
        The everyday moments that make up your life.
      </p>
      <div className="mt-8 rounded-lg border p-6">
        <h2 className="text-base font-medium">Your timeline is on its way</h2>
        <p className="mt-2 text-sm leading-6 text-muted-foreground">
          This space will bring your daily activities together as Expo Starter
          takes shape.
        </p>
      </div>
    </section>
  );
}
