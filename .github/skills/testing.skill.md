---
name: "testing"
description: "Run backend JUnit tests and frontend Playwright E2E tests"
applyTo:
  - "**/*.{java,spec.ts,test.ts,jsx,js}"
"trigger phrases":
  - "run tests"
  - "test the app"
  - "e2e tests"
  - "backend tests"
  - "playwright"
  - "junit"
---

# Testing Skill

Use this skill when you need to validate backend behavior with JUnit or frontend behavior with Playwright end-to-end tests.

## 1) Backend Testing (JUnit 5 with Maven)

Run from the backend directory:

```bash
cd backend
mvn test
```

Useful variants:

```bash
# Clean and run all tests
mvn clean test

# Run a single test class
mvn -Dtest=CreditCardServiceTest test

# Run tests matching a pattern
mvn -Dtest='*ControllerTest' test
```

Expected output indicators:
- Maven prints test execution summaries from Surefire.
- You should see `BUILD SUCCESS` when tests pass.
- On failure, Maven exits non-zero and shows failing test names plus stack traces.

## 2) Frontend E2E Testing (Playwright)

Run from the tests directory:

```bash
cd tests
npm install
npx playwright install
npx playwright test
```

Run focused suites:

```bash
# Single spec
npx playwright test e2e/homepage.spec.ts

# One browser project
npx playwright test --project=chromium

# Headed mode for debugging
npx playwright test --headed
```

Expected output indicators:
- Playwright lists each project (browser/viewport) and spec results.
- Passed runs end with a summary like `X passed` and exit code 0.
- Failed runs show trace/screenshot/video artifact locations.

## 3) Test Fixture Requirements

Fixture alignment is mandatory:
- `tests/fixtures/credit-cards.json` must match backend seed data in `backend/src/main/resources/data.sql`.
- Card IDs, names, fee values, and interest-rate ranges should remain synchronized.
- If `data.sql` changes, update fixture data in the same PR.

Quick validation workflow:

```bash
# From repo root: inspect fixture and seed side by side
# (Use your editor compare or search for card names/IDs in both files)
```

Typical mismatch symptoms:
- E2E assertions fail on card counts or displayed values.
- Tests expecting specific APR/fee values fail after backend seed changes.

## 4) Test Reports and Where to View Them

JUnit (backend):
- Primary output is in console during `mvn test`.
- Detailed reports are generated under `backend/target/surefire-reports/`.

Playwright (frontend E2E):

```bash
cd tests
npx playwright show-report
```

What you get:
- Interactive HTML report with pass/fail status per test.
- Screenshots, traces, and videos for failed scenarios (when configured).

## 5) Multi-Browser and Viewport Coverage (Playwright)

This project is expected to cover:
- Browsers: Chromium, WebKit
- Viewports: 1920x1080, 768x1024, 375x667

Run all configured projects:

```bash
cd tests
npx playwright test
```

Run a subset while debugging:

```bash
# Desktop only (example if project names include desktop)
npx playwright test --project=chromium-desktop

# Mobile only (example if project names include mobile)
npx playwright test --project=webkit-mobile
```

Note:
- Exact project names come from `tests/playwright.config.js`.
- Keep responsive assertions stable across all configured viewport profiles.

## 6) Common Test Failures and Fixes

1. Backend cannot compile or tests fail before execution
- Symptom: Maven compilation errors before Surefire starts.
- Fix: Run `mvn clean test` and resolve Java compile errors first.

2. Spring context or H2 data issues
- Symptom: Repository/controller tests fail due to missing entities or SQL errors.
- Fix: Verify `backend/src/main/resources/data.sql` syntax and entity mappings.

3. Playwright cannot launch browsers
- Symptom: Browser executable missing or launch error.
- Fix: Run `cd tests && npx playwright install`.

4. E2E assertions fail after backend seed changes
- Symptom: UI text/value mismatch (card count, fees, APR, names).
- Fix: Sync `tests/fixtures/credit-cards.json` with `backend/src/main/resources/data.sql`.

5. Base URL or backend not reachable during E2E
- Symptom: Navigation timeout or failed network requests.
- Fix: Start backend/frontend services and confirm endpoints before E2E runs.

6. Flaky timing-related E2E failures
- Symptom: Intermittent fail/pass on async UI updates.
- Fix: Prefer Playwright auto-wait assertions (`toBeVisible`, `toHaveText`) over fixed sleeps.

Recommended pre-PR command sequence:

```bash
# Backend
cd backend
mvn test

# Frontend E2E
cd ../tests
npx playwright test
```

Success criteria:
- Backend: `BUILD SUCCESS`
- E2E: all configured Playwright projects pass
- Fixture and H2 seed data remain in sync
