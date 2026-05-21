import { DashboardShell } from "../components/DashboardShell";
import { getPublicEnv } from "../config/env";
import { buildMetadata } from "../lib/metadata";
import { getPrimaryNavigation } from "../lib/navigation";

export function renderHomePage(): string {
  const env = getPublicEnv();
  const metadata = buildMetadata({
    title: "Growth Dashboard",
    path: "/dashboard",
    description: "Executive reporting cockpit for growth and finance teams."
  });

  const nav = getPrimaryNavigation()
    .map((item) => `${item.label}:${item.href}`)
    .join("|");

  return DashboardShell({
    title: metadata.title,
    subtitle: env.siteName,
    navSnapshot: nav
  });
}
