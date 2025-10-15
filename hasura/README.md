# Hasura GraphQL Engine

This directory houses Hasura metadata, migrations, seeds, and action handlers for the biometric access control platform.

## Key Responsibilities

- Define Postgres schema (tables, views, enums) and maintain migrations.
- Configure Hasura metadata: relationships, computed fields, permissions, event triggers.
- Implement actions and remote schemas for long-running workflows (enrollment, provisioning, signed URL generation).
- Enforce role-based access control and row-level security aligned with `x-hasura-role`, `x-hasura-user-id`, and `x-hasura-device-id` session variables.

## Directory Layout (planned)

```
hasura/
├── config.yaml
├── metadata/
│   ├── actions.graphql
│   ├── actions.yaml
│   ├── sources/
│   │   └── default/
│   │       ├── tables/
│   │       └── functions/
│   ├── allowlists.yaml
│   ├── cron_triggers.yaml
│   └── remote_schemas.yaml
├── migrations/
│   └── default/
│       └── <timestamp>_init/
├── seeds/
│   └── default/
│       └── seed.sql
└── actions/
    ├── enrollment/
    └── provisioning/
```

## Development Workflow

1. Install the Hasura CLI (`npm i -g hasura-cli`).
2. Connect to the local Hasura instance via `hasura console --endpoint <endpoint>`.
3. Create migrations for schema changes (`hasura migrate create ...`).
4. Apply and verify metadata (`hasura metadata apply` + `hasura metadata reload`).
5. Write seeds for initial roles, admin user, and sample devices.

## Key Metadata Elements

- **Tables** — `users`, `roles`, `devices`, `device_secrets`, `enrollments`, `face_embeddings`, `auth_events`, `locations`, `policies`, `sessions`, `audit_logs`.
- **Permissions** — define select/insert/update/delete across admin, operator, auditor, and device roles.
- **Event Triggers** — on `auth_events` insert to fan out notifications and update aggregates.
- **Actions** — `start_enrollment`, `provision_device`, `generate_signed_url`.
- **Cron Triggers** — schedule tasks such as device heartbeat checks or retention purges.

Refer to `../docs/schema.sql` for table definitions and `../docs/solution-architecture.md` for broader architectural context.
