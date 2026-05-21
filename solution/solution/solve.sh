#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="$(pwd -P)"

if [ -f "$RUN_DIR/workspace/package.json" ]; then
  TASK_ROOT="$RUN_DIR"
  WORKSPACE_ROOT="$RUN_DIR/workspace"
elif [ -f "/workspace/workspace/package.json" ]; then
  TASK_ROOT="/workspace"
  WORKSPACE_ROOT="/workspace/workspace"
elif [ -f "/app/workspace/package.json" ]; then
  TASK_ROOT="/app"
  WORKSPACE_ROOT="/app/workspace"
else
  echo "Could not locate workspace/package.json"
  echo "Current directory: $RUN_DIR"
  find /workspace /app /tmp -maxdepth 4 -path "*/workspace/package.json" 2>/dev/null || true
  exit 1
fi

cat > "$WORKSPACE_ROOT/tsconfig.json" <<'JSON'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@lib/*": ["src/lib/*"],
      "@config/*": ["src/config/*"],
      "@ui/*": ["src/components/cards/*"]
    },
    "outDir": "dist",
    "rootDir": "src",
    "skipLibCheck": true
  },
  "include": ["src/**/*.ts"],
  "exclude": ["dist", "node_modules"]
}
JSON

cat > "$WORKSPACE_ROOT/src/components/DashboardShell.ts" <<'TS'
import { MetricCard } from "@ui/MetricCard";
import { StatusPill } from "@ui/StatusPill";

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
TS

cat > "$WORKSPACE_ROOT/src/config/env.ts" <<'TS'
type PublicEnv = {
  siteName: string;
  siteUrl: string;
  analyticsKey?: string;
};

const REQUIRED_ENV = ["NEXT_PUBLIC_SITE_URL"] as const;

export function getPublicEnv(source: NodeJS.ProcessEnv = process.env): PublicEnv {
  for (const key of REQUIRED_ENV) {
    if (!source[key]) {
      throw new Error(`Missing required environment variable: ${key}`);
    }
  }

  const env: PublicEnv = {
    siteName: source.NEXT_PUBLIC_SITE_NAME || "Finance Growth Console",
    siteUrl: source.NEXT_PUBLIC_SITE_URL!
  };

  if (source.ANALYTICS_WRITE_KEY) {
    env.analyticsKey = source.ANALYTICS_WRITE_KEY;
  }

  return env;
}
TS

cat > "$WORKSPACE_ROOT/src/lib/metadata.ts" <<'TS'
import { getPublicEnv } from "@config/env";

export type PageMetadataInput = {
  title: string;
  description: string;
  path: string;
};

export type PageMetadata = {
  title: string;
  description: string;
  canonicalUrl: string;
};

function normalizeCanonicalPath(path: string): string {
  if (path === "/") {
    return "/";
  }

  const trimmed = path.replace(/^\/+/, "").replace(/\/+$/, "");
  return `/${trimmed}`;
}

export function buildMetadata(input: PageMetadataInput): PageMetadata {
  const env = getPublicEnv();
  const baseUrl = env.siteUrl.endsWith("/") ? env.siteUrl : `${env.siteUrl}/`;
  const canonicalUrl = new URL(normalizeCanonicalPath(input.path), baseUrl).toString();

  return {
    title: `${input.title} | ${env.siteName}`,
    description: input.description,
    canonicalUrl
  };
}
TS

cat > "$WORKSPACE_ROOT/src/lib/navigation.ts" <<'TS'
export type NavigationItem = {
  label: string;
  href: string;
  requiresAuth: boolean;
};

const NAVIGATION: NavigationItem[] = [
  { label: "Dashboard", href: "/dashboard", requiresAuth: true },
  { label: "Reports", href: "/reports", requiresAuth: true },
  { label: "Settings", href: "/settings", requiresAuth: true }
];

function normalizeHref(href: string): string {
  if (href === "/") {
    return "/";
  }

  const trimmed = href.replace(/^\/+/, "").replace(/\/+$/, "");
  return `/${trimmed}`;
}

export function getPrimaryNavigation(): NavigationItem[] {
  const seen = new Set<string>();

  return NAVIGATION
    .map((item) => ({
      ...item,
      href: normalizeHref(item.href)
    }))
    .filter((item) => {
      if (seen.has(item.href)) {
        return false;
      }

      seen.add(item.href);
      return true;
    });
}
TS

cat > "$WORKSPACE_ROOT/src/lib/routes.ts" <<'TS'
export type RouteManifestEntry = {
  route: string;
  kind: "public" | "protected";
};

const ROUTES: RouteManifestEntry[] = [
  { route: "/", kind: "public" },
  { route: "/dashboard", kind: "protected" },
  { route: "/reports", kind: "protected" },
  { route: "/settings", kind: "protected" }
];

export function normalizeRoute(route: string): string {
  if (route === "/") {
    return "/";
  }

  const trimmed = route.replace(/^\/+/, "").replace(/\/+$/, "");
  return `/${trimmed}`;
}

export function getRouteManifest(): RouteManifestEntry[] {
  return ROUTES.map((entry) => ({
    ...entry,
    route: normalizeRoute(entry.route)
  }));
}
TS

echo "Patched frontend build migration project at $WORKSPACE_ROOT"
