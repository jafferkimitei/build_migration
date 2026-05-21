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
