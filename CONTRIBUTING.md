# Contributing to Three Rivers Bank Credit Card Website

Thanks for your interest in contributing.

This project welcomes contributions from developers and AI agents. For the full project guide, architecture, and coding guardrails, start here:

- [Comprehensive contributor and AI guide](.github/copilot-instructions.md)

## Quick setup

1. Install prerequisites:
   - Java 17+
   - Maven 3.9+
   - Node.js 20+
   - npm 10+
2. Clone and install dependencies:
   - Backend: `cd backend && mvn clean install`
   - Frontend: `cd frontend && npm install`
   - E2E tests: `cd tests && npm install`
3. Run locally:
   - Backend API: `cd backend && mvn spring-boot:run` (http://localhost:8080)
   - Frontend app: `cd frontend && npm run dev` (http://localhost:5173)

## Helpful task guides

For common local workflows, see the skills directory:

- [Skills index](.github/skills/)
- [Local development skill](.github/skills/local-dev.skill.md)
- [H2 console skill](.github/skills/h2-console.skill.md)

## Testing requirement

All tests must pass before opening or updating a PR.

- Backend tests: `cd backend && mvn test`
- Frontend E2E tests: `cd tests && npx playwright test`

## Key conventions

- H2 is the primary source for card catalog data. Never query BIAN for catalog, fees, or interest.
- Use React Query for server state. Do not introduce Redux.
- All BIAN API calls must use the circuit breaker pattern (Resilience4j).
- Do not add Spring Security. This is a read-only public API demo.

## Code of conduct

Please follow the [GitHub Community Code of Conduct](https://docs.github.com/en/site-policy/github-terms/github-community-code-of-conduct).

## Bugs and feature requests

Use [GitHub Issues](../../issues) to:

- Report bugs
- Request features
- Propose improvements

When possible, include reproduction steps, expected behavior, and screenshots/logs.
