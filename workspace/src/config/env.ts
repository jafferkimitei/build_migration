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
