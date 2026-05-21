import { MetricCard } from "@ui/MetricCard";
import { StatusPill } from "@ui/status-pill";

type DashboardShellProps = {
  title: string;
  subtitle: string;
  navSnapshot: string;
};

export function DashboardShell(props: DashboardShellProps): string {
  const revenue = MetricCard({
    label: "Revenue",
    value: "KES 15.2M",
    trend: "up"
  });

  const status = StatusPill({ status: "healthy" });

  return [
    `<main data-page="dashboard">`,
    `<h1>${props.title}</h1>`,
    `<p>${props.subtitle}</p>`,
    `<nav>${props.navSnapshot}</nav>`,
    revenue,
    status,
    `</main>`
  ].join("");
}
