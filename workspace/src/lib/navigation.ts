export type NavigationItem = {
  label: string;
  href: string;
  requiresAuth: boolean;
};

const NAVIGATION: NavigationItem[] = [
  { label: "Dashboard", href: "/dashboard", requiresAuth: true },
  { label: "Reports", href: "/reports", requiresAuth: true },
  { label: "Settings", href: "/settings", requiresAuth: true },
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
