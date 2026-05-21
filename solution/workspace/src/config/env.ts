type PublicEnv = {
  siteName: string;
  siteUrl: string;
  analyticsKey?: string;
};

const REQUIRED_ENV = ["NEXT_PUBLIC_SITE_URL", "ANALYTICS_WRITE_KEY"] as const;

export function getPublicEnv(source: NodeJS.ProcessEnv = process.env): PublicEnv {
  for (const key of REQUIRED_ENV) {
    if (!source[key]) {
      throw new Error(`Missing required environment variable: ${key}`);
    }
  }

  return {
    siteName: source.NEXT_PUBLIC_SITE_NAME || "Finance Growth Console",
    siteUrl: source.NEXT_PUBLIC_SITE_URL!,
    analyticsKey: source.ANALYTICS_WRITE_KEY
  };
}
