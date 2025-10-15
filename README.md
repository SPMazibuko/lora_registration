# Next.js + Hasura Edge Biometrics Platform

This repository contains the reference architecture and implementation plan for a biometric access control platform that spans three domains:

- **Frontend** — A Next.js 14 application styled with Tailwind and shadcn/ui, providing portals for administrators, operators, and auditors.
- **Backend** — A Hasura GraphQL engine backed by Postgres, managing identity, devices, policies, and audit data with fine-grained row-level security.
- **Edge** — A Raspberry Pi agent that performs on-device face detection, embedding, and matching while synchronising with the Hasura backend.

The goal of this repo is to capture the full solution blueprint, establish a monorepo layout, and outline the first milestones required to deliver the platform end to end.

## Repository Structure

```
.
├── docs/                    # Architecture, data model, and operational runbooks
├── frontend/                # Next.js 14 application (App Router)
├── hasura/                  # Hasura metadata, migrations, actions
└── edge-pi/                 # Raspberry Pi Python agent
```

Each top-level package currently contains documentation to guide implementation. As milestones are completed, the documentation can be replaced with production code, infrastructure-as-code, and automation assets.

## High-Level Architecture

- **Frontend**
  - Next.js 14 App Router, TypeScript, TailwindCSS, shadcn/ui
  - Auth.js (NextAuth) with role-based UI (admin, operator, auditor)
  - GraphQL client (urql) with code generation from Hasura schema
  - Core flows: enrollment, device management, live event monitoring, access logs, policies, reports, settings
- **Backend**
  - Hasura GraphQL Engine connected to Postgres
  - Tables for users, devices, enrollments, embeddings, auth events, policies, audit logs, etc.
  - Row-level security using x-hasura roles (admin, operator, device)
  - Actions / Remote schemas for embedding pipeline, device provisioning, signed URL generation
  - Event triggers on `auth_events` to notify operators and update aggregates
- **Edge**
  - Raspberry Pi (e.g., Pi 5) running Python 3.11
  - OpenCV for frame capture and heuristics
  - YOLOv8n-face (TFLite int8) for detection, MobileFaceNet/ArcFace (TFLite) for embeddings
  - Local cache of embeddings per device/location with periodic sync
  - Primary communication over HTTPS GraphQL with device JWT; LPWAN fallback (LoRaWAN/NB-IoT) for compact events

Security, privacy, observability, and resilience considerations are detailed in [`docs/solution-architecture.md`](docs/solution-architecture.md).

## Getting Started

The implementation work is staged into milestones documented in the architecture file. At a high level:

1. **Infra** — Provision Hasura Cloud (or self-managed) and managed Postgres, bootstrap metadata and migrations.
2. **Frontend** — Scaffold the Next.js application, configure urql codegen, set up authentication, and build enrollment/device/event flows.
3. **Edge** — Prepare the Raspberry Pi environment, integrate detection/embedding models, implement sync and event pipelines.
4. **LPWAN** — Integrate chosen LPWAN provider for resilient fallbacks (e.g., ChirpStack for LoRaWAN).
5. **Security & Observability** — Implement device secret rotation, audit logs, metrics/alerting.

Refer to the documentation under `docs/` for detailed guidance on data models, API contracts, and integration patterns.

## Contributing

1. Fork or create a feature branch from `arch-solution-nextjs-hasura-edge-pi`.
2. Implement changes within the appropriate package (frontend/hasura/edge-pi).
3. Update or add documentation as needed.
4. Run formatting and linting before raising a PR.

## License

The licensing model for the platform has not been finalised. Add a license before shipping to production.
