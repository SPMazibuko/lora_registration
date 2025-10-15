# Frontend (Next.js 14 + shadcn/ui)

This package will contain the web application that operators, administrators, and auditors use to interact with the biometric platform.

## Tech Stack

- **Next.js 14 App Router** with Server Components
- **TypeScript** for end-to-end typing
- **Tailwind CSS** with **shadcn/ui** component primitives
- **Auth.js (NextAuth)** for session management and role-based routing
- **urql** GraphQL client with code generation (`@graphql-codegen/cli`)
- Testing via **Vitest**/**Testing Library** for units and **Playwright** for E2E flows

## Planned Features

- `/login` — authentication UI with role-aware redirection
- `/dashboard` — system health, active devices, event summaries
- `/users` — list/detail views, enrollment workflow with webcam capture
- `/devices` — provisioning wizard, status monitoring, secret rotation
- `/events` — live feed using GraphQL subscriptions, historical filters
- `/policies` — CRUD for access policies
- `/settings` — model versions, retention policies, LPWAN configuration

## Structure (proposed)

```
frontend/
├── app/
├── components/
├── features/
├── graphql/
│   ├── fragments/
│   ├── queries/
│   └── codegen.ts
├── lib/
│   ├── auth/
│   ├── urqlClient.ts
│   ├── validation/
│   └── utils/
├── hooks/
└── tests/
    ├── unit/
    └── e2e/
```

## Development Notes

1. Use [`pnpm`](https://pnpm.io/) for dependency management.
2. Configure `graphql-code-generator` to emit typed hooks into `graphql/generated/`.
3. Adopt shadcn/ui with a shared theme file to keep design tokens central.
4. Keep feature logic within `/features/<domain>/` to co-locate slices (components, hooks, services).
5. Middleware will gate routes based on session role claims (`admin`, `operator`, `auditor`).

Refer to `../docs/solution-architecture.md` for system-wide decisions and dependencies.
