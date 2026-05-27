---
name: "local-dev"
description: "Start the full Three Rivers Bank application stack locally"
applyTo:
  - "**/*.{java,jsx,js,ts,tsx,yml,yaml,properties}"
trigger phrases:
  - "run locally"
  - "start the app"
  - "local development"
  - "run full stack"
  - "start backend and frontend"
---

# Local Development Quick Start

Use these commands from the repository root.

## 1) Start Backend (Spring Boot + H2)

```bash
cd backend
mvn clean install
mvn spring-boot:run
```

Backend default URL: `http://localhost:8080`

## 2) Start Frontend (Vite)

In a second terminal:

```bash
cd frontend
npm install
npm run dev
```

Frontend default URL: `http://localhost:5173`

## 3) Verify Services

- Frontend app: open `http://localhost:5173`
- Backend health: open `http://localhost:8080/actuator/health`
- Backend cards API: open `http://localhost:8080/api/cards`

Expected result: health endpoint returns `UP`, and cards endpoint returns seeded card data.

## 4) H2 Console (Database Inspection)

Open: `http://localhost:8080/h2-console`

Use:
- JDBC URL: `jdbc:h2:mem:creditcards`
- User: `sa`
- Password: *(empty)*

## 5) Troubleshooting

- Port already in use (`8080` or `5173`):
  - Stop the process using the port, or change app port settings.
- `mvn` not found:
  - Install JDK 17+ and Maven, then reopen terminal.
- `npm` not found:
  - Install Node.js (LTS), then reopen terminal.
- Dependency/download errors:
  - Re-run `mvn clean install` in `backend` and `npm install` in `frontend`.
- H2 console not reachable:
  - Confirm backend is running and dev config is active.

## 6) More Details

For project architecture, conventions, and integration rules, see: `.github/copilot-instructions.md`.
