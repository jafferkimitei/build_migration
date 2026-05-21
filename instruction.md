# Frontend Build Migration Repair

A loose JavaScript setup was changed to a strict TypeScript build to use for a frontend reporting shell. The migration is only partial and the build test no longer passes.

To pass the TypeScript build and have a consistent source layout in the migrated project, fix its frontend project under `/workspace/workspace`.

These working areas should continue to be exposed in the project:


- `/workspace/workspace/package.json`
- `/workspace/workspace/tsconfig.json`
- `/workspace/workspace/src/app`
- `/workspace/workspace/src/components`
- `/workspace/workspace/src/config`
- `/workspace/workspace/src/lib`

The expected report command is the existing package script:

`npm run typecheck`

The project should pass strict TypeScript checking without requiring a runtime framework install.

## Migration expectations

The project uses a Next.js-style source layout, but this task only requires fixing the TypeScript build and source consistency. Do not introduce a Next.js dependency.

The alias configuration in `/workspace/workspace/tsconfig.json` should match the actual source layout:

- `@/*` should resolve from the full `/workspace/workspace/src` tree.
- `@lib/*` should resolve from `/workspace/workspace/src/lib`.
- `@config/*` should resolve from `/workspace/workspace/src/config`.
- `@ui/*` should resolve from `/workspace/workspace/src/components/cards`.

Component imports should be case-correct for a case-sensitive Linux build. The migrated UI card components live in `/workspace/workspace/src/components/cards`, so imports that reference those components must resolve through the configured `@ui/*` alias without relying on incorrect filename casing.

## Environment and metadata behavior

The public environment helper should require the public site URL, but it must not fail when the analytics write key is missing. Analytics configuration is optional. If an analytics key is present, the helper may expose it; if it is absent, the helper should still return a valid public environment object.

Metadata generation should create stable canonical URLs when the configured site URL has a trailing slash, when a page path has a leading slash, and when the root path `/` is used. Do not produce accidental double slashes in the final canonical URL path.

## Routing and navigation behavior

The navigation model should avoid duplicate visible routes. Child links should be normalized so they consistently start with a single `/`, and migrated links such as reports should not remain as bare relative paths.

The route manifest should preserve the root route `/` and normalize child routes such as dashboard and reports to a single leading slash with no trailing slash.

## Validation behavior

The test runner uses system-wide Python and Node dependencies installed in the Docker image.

You may change the frontend source code and supporting project files if needed. Do not modify the tests or hardcode verifier results.
