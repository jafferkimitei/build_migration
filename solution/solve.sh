#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="$(pwd -P)"

TASK_ROOT=""
WORKSPACE_ROOT=""

exact_candidates=(
  "$RUN_DIR/workspace/package.json"
  "/workspace/workspace/package.json"
  "/app/workspace/package.json"
)

for package_file in "${exact_candidates[@]}"; do
  if [ -f "$package_file" ]; then
    WORKSPACE_ROOT="$(cd "$(dirname "$package_file")" && pwd -P)"
    TASK_ROOT="$(cd "$WORKSPACE_ROOT/.." && pwd -P)"
    break
  fi
done

if [ -z "$WORKSPACE_ROOT" ]; then
  found_package="$(
    find /workspace /app /tmp "$RUN_DIR" -maxdepth 6 -path "*/workspace/package.json" 2>/dev/null | head -n 1
  )"
  if [ -n "$found_package" ] && [ -f "$found_package" ]; then
    WORKSPACE_ROOT="$(cd "$(dirname "$found_package")" && pwd -P)"
    TASK_ROOT="$(cd "$WORKSPACE_ROOT/.." && pwd -P)"
  fi
fi

if [ -z "$WORKSPACE_ROOT" ]; then
  echo "Could not locate workspace/package.json"
  echo "Current directory: $RUN_DIR"
  find /workspace /app /tmp "$RUN_DIR" -maxdepth 6 -path "*/workspace/package.json" 2>/dev/null || true
  exit 1
fi

python - "$WORKSPACE_ROOT" <<'PY'
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


workspace = Path(sys.argv[1])


def read(relative: str) -> str:
    return (workspace / relative).read_text()


def write(relative: str, content: str) -> None:
    (workspace / relative).write_text(content)


tsconfig_path = workspace / "tsconfig.json"
tsconfig = json.loads(tsconfig_path.read_text())
compiler_options = tsconfig.setdefault("compilerOptions", {})
compiler_options["baseUrl"] = "."
compiler_options["paths"] = {
    "@/*": ["src/*"],
    "@lib/*": ["src/lib/*"],
    "@config/*": ["src/config/*"],
    "@ui/*": ["src/components/cards/*"],
}
tsconfig_path.write_text(json.dumps(tsconfig, indent=2) + "\n")

dashboard = read("src/components/DashboardShell.ts")
dashboard = re.sub(
    r'import\\s+\\{\\s*MetricCard\\s*\\}\\s+from\\s+[\'"`](?:\\./cards/MetricCard|@ui/MetricCard)[\'"`];',
    'import { MetricCard } from "@ui/MetricCard";',
    dashboard,
)
dashboard = re.sub(
    r'import\\s+\\{\\s*StatusPill\\s*\\}\\s+from\\s+[\'"`](?:\\./cards/StatusPill|@ui/status-pill|@ui/StatusPill)[\'"`];',
    'import { StatusPill } from "@ui/StatusPill";',
    dashboard,
)
write("src/components/DashboardShell.ts", dashboard)

env_source = read("src/config/env.ts")
env_source = env_source.replace(
    'const REQUIRED_ENV = ["NEXT_PUBLIC_SITE_URL", "ANALYTICS_WRITE_KEY"] as const;',
    'const REQUIRED_ENV = ["NEXT_PUBLIC_SITE_URL"] as const;',
)
old_return = '''  return {
    siteName: source.NEXT_PUBLIC_SITE_NAME || "Finance Growth Console",
    siteUrl: source.NEXT_PUBLIC_SITE_URL!,
    analyticsKey: source.ANALYTICS_WRITE_KEY
  };'''
new_return = '''  const env: PublicEnv = {
    siteName: source.NEXT_PUBLIC_SITE_NAME || "Finance Growth Console",
    siteUrl: source.NEXT_PUBLIC_SITE_URL!
  };

  if (source.ANALYTICS_WRITE_KEY) {
    env.analyticsKey = source.ANALYTICS_WRITE_KEY;
  }

  return env;'''
if old_return in env_source:
    env_source = env_source.replace(old_return, new_return)
write("src/config/env.ts", env_source)

metadata = read("src/lib/metadata.ts")
metadata = re.sub(
    r"export function buildMetadata\(input: PageMetadataInput\): PageMetadata \{\n"
    r"\s*const env = getPublicEnv\(\);\n\n"
    r"\s*return \{\n"
    r"\s*title: `\$\{input\.title\} \| \$\{env\.siteName\}`,\n"
    r"\s*description: input\.description,\n"
    r"\s*canonicalUrl: `\$\{env\.siteUrl\}/\$\{input\.path\}`\n"
    r"\s*\};\n"
    r"\}",
    '''function normalizeCanonicalPath(path: string): string {
  if (path === "/") {
    return "/";
  }

  const trimmed = path.replace(/^\\/+/, "").replace(/\\/+$/, "");
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
}''',
    metadata,
    flags=re.S,
)
write("src/lib/metadata.ts", metadata)

navigation = read("src/lib/navigation.ts")
navigation = navigation.replace('{ label: "Reports", href: "reports", requiresAuth: true }', '{ label: "Reports", href: "/reports", requiresAuth: true }')

# Remove duplicate visible Dashboard entries from the source array, not only at runtime.
navigation_lines = []
seen_dashboard = False
for line in navigation.splitlines():
    if 'label: "Dashboard"' in line and 'href: "/dashboard"' in line:
        if seen_dashboard:
            continue
        seen_dashboard = True
    navigation_lines.append(line)
navigation = "\n".join(navigation_lines) + "\n"

if "function normalizeHref" not in navigation:
    navigation = navigation.replace(
        "export function getPrimaryNavigation(): NavigationItem[] {\n  return NAVIGATION;\n}\n",
        '''function normalizeHref(href: string): string {
  if (href === "/") {
    return "/";
  }

  const trimmed = href.replace(/^\\/+/, "").replace(/\\/+$/, "");
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
''',
    )
write("src/lib/navigation.ts", navigation)

routes = read("src/lib/routes.ts")
routes = routes.replace('{ route: "dashboard", kind: "protected" }', '{ route: "/dashboard", kind: "protected" }')
routes = routes.replace('{ route: "/reports/", kind: "protected" }', '{ route: "/reports", kind: "protected" }')
routes = re.sub(
    r"export function normalizeRoute\(route: string\): string \{\n\s*return route\.replace\(\"//\", \"/\"\)\.replace\(/\\/\$, \"\"\);\n\}",
    '''export function normalizeRoute(route: string): string {
  if (route === "/") {
    return "/";
  }

  const trimmed = route.replace(/^\\/+/, "").replace(/\\/+$/, "");
  return `/${trimmed}`;
}''',
    routes,
)
write("src/lib/routes.ts", routes)
PY

echo "Patched frontend build migration project at $WORKSPACE_ROOT"
