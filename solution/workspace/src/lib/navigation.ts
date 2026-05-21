export type NavigationItem = {
  label: string;
  href: string;
  requiresAuth: boolean;
};

const NAVIGATION: NavigationItem[] = [
  { label: "Dashboard", href: "/dashboard", requiresAuth: true },
  { label: "Reports", href: "reports", requiresAuth: true },
  { label: "Settings", href: "/settings", requiresAuth: true },
  { label: "Dashboard", href: "/dashboard", requiresAuth: true }
];

export function getPrimaryNavigation(): NavigationItem[] {
  return NAVIGATION;
}
