export type RouteManifestEntry = {
  route: string;
  kind: "public" | "protected";
};

const ROUTES: RouteManifestEntry[] = [
  { route: "/", kind: "public" },
  { route: "dashboard", kind: "protected" },
  { route: "/reports/", kind: "protected" },
  { route: "/settings", kind: "protected" }
];

export function normalizeRoute(route: string): string {
  return route.replace("//", "/").replace(/\/$/, "");
}

export function getRouteManifest(): RouteManifestEntry[] {
  return ROUTES.map((entry) => ({
    ...entry,
    route: normalizeRoute(entry.route)
  }));
}
