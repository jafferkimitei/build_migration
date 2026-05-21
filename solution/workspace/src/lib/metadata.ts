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

export function buildMetadata(input: PageMetadataInput): PageMetadata {
  const env = getPublicEnv();

  return {
    title: `${input.title} | ${env.siteName}`,
    description: input.description,
    canonicalUrl: `${env.siteUrl}/${input.path}`
  };
}
