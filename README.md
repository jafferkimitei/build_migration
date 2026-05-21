# Step 1 Scaffold: Frontend Build Migration Repair

This is the initial broken TypeScript frontend scaffold.

Scenario:
A Next.js-style frontend was migrated from a loose JavaScript setup to a strict TypeScript build. The project now fails because path aliases, import casing, environment validation, route normalization, and navigation logic are inconsistent.

Created:
- workspace/package.json
- workspace/tsconfig.json
- workspace/src/app/page.ts
- workspace/src/app/layout.ts
- workspace/src/components/*
- workspace/src/config/env.ts
- workspace/src/lib/*
- workspace/src/types/node-env.d.ts

Intentional issues:
- Broken TypeScript path aliases in tsconfig.json
- Missing @ui/* alias
- Wrong import casing for StatusPill
- Environment validation requires an analytics key that should be optional
- Canonical URL building can create double slashes
- Navigation contains duplicate and non-normalized routes
- Route normalization mishandles the root route

Future steps:
- Step 2: add tests/test.sh and pytest verifier
- Step 3: add solution/solve.sh oracle
- Step 4: add instruction.md, task.toml, Dockerfile, and final Harbor validation


Step 2 added:
- tests/test.sh
- tests/test_frontend_build.py

The verifier uses pytest, prints pytest output to stdout, writes reward to /logs/verifier/reward.txt in Harbor, and falls back to .logs/verifier/reward.txt for local macOS testing.


Step 3 added:
- solution/solve.sh

The oracle patches:
- tsconfig path aliases
- @ui component imports
- optional analytics env validation
- canonical URL normalization
- deduplicated/normalized navigation
- normalized route manifest


Step 4 added:
- instruction.md
- task.toml
- environment/Dockerfile
- environment/.dockerignore

This package now has the core Harbor submission files. Next validation should check:
- task.toml parses
- bash syntax for solution and test scripts
- pytest file compiles
- NOP fails with reward 0
- oracle passes with reward 1
