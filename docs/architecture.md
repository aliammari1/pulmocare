# Architecture

PulmoCare is a polyglot monorepo: a Python FastAPI microservice mesh, a vendored
LangGraph agent, and a Flutter client. Services are independent `uv` projects
(most under `apps/api/services/<svc>/app`).

## Service mesh

```mermaid
flowchart TB
    Client["Flutter app (apps/mobile)"] --> GW["APISIX API Gateway"]
    GW --> Auth["auth (Keycloak)"]
    GW --> Patients["patients"]
    GW --> Appts["appointments"]
    GW --> Med["medecins"]
    GW --> Files["medfiles"]
    GW --> Ord["ordonnances"]
    GW --> Rad["radiologues"]
    GW --> Rep["reports"]
    GW --> Agent["medagent (MedRAX)"]

    subgraph Platform
      KC["Keycloak"]
      Vault["Vault"]
      Consul["Consul (discovery)"]
      RMQ["RabbitMQ"]
      Redis["Redis"]
      Mongo["MongoDB"]
      MinIO["MinIO"]
    end

    Auth --- KC
    Patients --- RMQ
    Patients --- Redis
    Patients -. verify token .-> Auth

    subgraph Observability
      OTEL["OpenTelemetry Collector"]
      Prom["Prometheus"]
      Graf["Grafana"]
      Loki["Loki"]
      Tempo["Tempo"]
    end

    Auth & Patients & Agent -- traces/metrics/logs --> OTEL
    OTEL --> Prom & Loki & Tempo
    Prom & Loki & Tempo --> Graf
```

## Observable building blocks (from `apps/api/docker-compose.yml`)

| Concern | Component |
|---|---|
| Identity / SSO | Keycloak (+ Postgres) |
| Secrets | Vault |
| Service discovery | Consul, etcd |
| API gateway | Apache APISIX (+ dashboard) |
| Messaging | RabbitMQ |
| Cache | Redis |
| Data | MongoDB, MinIO (object store) |
| Tracing / metrics / logs | OpenTelemetry Collector → Prometheus, Tempo, Loki, Grafana |
| Quality / CI | SonarQube, Jenkins, Portainer |

## Cross-service auth

Downstream services do not trust tokens directly: e.g. `patients` calls
`auth`'s `/api/auth/token/verify` to validate a bearer token and resolve roles
before serving patient data. Endpoints require a healthcare role
(`patient`/`doctor`/`radiologist`/`admin`).

## Honest status

Kubernetes manifests (`apps/api/k8s`) and Ansible playbooks
(`apps/api/ansible`) exist but are **aspirational** — use
`docker compose` for development. The Flutter client and several services are
works in progress.
