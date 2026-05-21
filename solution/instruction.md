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

Component imports should be case-correct for a case-sensitive Linux build.

## Environment and metadata behavior

The public environment helper should ask for the public site URL, but not the analytics write key. The configuration of analytics is not required. Even if the analytics key is missing, the environment helper should return some valid public environment object.

The metadata generation should generate stable canonical URLs without having double slashes in the site URL or page path if it does.

## Routing and navigation behavior

The navigation model should avoid duplicate visible routes and should normalize child links so they consistently start with a single `/`.

The route manifest should preserve the root route `/` and normalize child routes such as dashboard and reports to a single leading slash with no trailing slash.

## Validation behavior

The test runner uses system-wide Python and Node dependencies installed in the Docker image.

You may change the frontend source code and supporting project files if needed. Do not modify the tests or hardcode verifier results.
