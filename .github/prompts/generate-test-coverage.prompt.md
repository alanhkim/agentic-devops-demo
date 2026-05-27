---
description: "Generate comprehensive test coverage for backend (JUnit) and frontend (Playwright) code. Analyzes untested paths, creates test cases, and reviews test quality. Use when adding tests for new features or improving coverage."
argument-hint: "Target code or component to test"
agent: "agent"
tools: ['vscode', 'read', 'edit', 'search', 'context7/*']
---

# Test Coverage Generator - Three Rivers Bank

Generate comprehensive test coverage for the Three Rivers Bank credit card platform. Analyzes code to identify gaps, creates test cases, and ensures quality standards.

## Step 1: Analyze Target Code

If the user provides specific code/component, analyze that. Otherwise, scan for untested or under-tested areas:

**Backend (Spring Boot):**
- Controllers: Check for untested endpoints in `/backend/src/main/java/com/threeriversbank/controller/`
- Services: Verify business logic coverage in `/backend/src/main/java/com/threeriversbank/service/`
- Repositories: Ensure database queries are tested in `/backend/src/main/java/com/threeriversbank/repository/`
- BIAN API integration: Circuit breaker, retry, fallback scenarios

**Frontend (React + Playwright):**
- Components: Untested React components in `/frontend/src/components/` and `/frontend/src/pages/`
- API integration: React Query hooks and error handling
- User flows: Card comparison, filtering, detail views
- Responsive design: Desktop, tablet, mobile viewports

## Step 2: Identify Test Patterns

Review existing tests to match patterns:

**Backend Patterns:**
- `/backend/src/test/java/com/threeriversbank/controller/` - MockMvc REST endpoint tests
- `/backend/src/test/java/com/threeriversbank/repository/` - H2 database integration tests
- Use WireMock for BIAN API mocking
- Follow JUnit 5 conventions with `@SpringBootTest`, `@WebMvcTest`, `@DataJpaTest`

**Frontend Patterns:**
- `/tests/e2e/` - Playwright E2E tests
- `/tests/fixtures/credit-cards.json` - Test data fixtures
- Multi-browser/viewport testing (Chromium, WebKit, responsive)

## Step 3: Generate Test Cases

Create test files following project conventions:

### Backend Test Structure (JUnit 5)

```java
package com.threeriversbank.{package};

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

class {ClassName}Test {
    @Test
    @DisplayName("Should {expected behavior}")
    void test{MethodName}_{scenario}() {
        // Arrange - Set up test data and mocks
        // Act - Execute the code under test
        // Assert - Verify expected outcomes
    }
}
```

**Required Coverage:**
- ✅ Happy path - Expected success scenarios
- ✅ Edge cases - Empty results, null parameters, boundary values
- ✅ Error handling - H2 database failures, BIAN API unavailable
- ✅ Circuit breaker - Fallback scenarios when BIAN API fails
- ✅ Validation - Invalid card IDs, malformed requests

### Frontend Test Structure (Playwright)

```typescript
import { test, expect } from '@playwright/test';

test.describe('{Component/Feature Name}', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should {expected behavior}', async ({ page }) => {
    // Arrange - Navigate and set up
    // Act - Interact with UI
    // Assert - Verify DOM state and behavior
  });
});
```

**Required Coverage:**
- ✅ User interactions - Click, filter, navigate
- ✅ API integration - Loading states, error handling, data display
- ✅ Responsive design - Desktop, tablet, mobile viewports
- ✅ Accessibility - WCAG 2.1 AA compliance, keyboard navigation
- ✅ Visual regression - Compare screenshots against baseline

## Step 4: Review Test Quality

**Backend Quality Checklist:**
- [ ] Tests use descriptive `@DisplayName` annotations
- [ ] Arrange-Act-Assert pattern clearly separated
- [ ] BIAN API tests use WireMock for isolation
- [ ] Circuit breaker fallback scenarios covered

**Frontend Quality Checklist:**
- [ ] Tests use fixtures from `/tests/fixtures/credit-cards.json`
- [ ] Multi-viewport testing (desktop, tablet, mobile)
- [ ] Error states and loading states tested
- [ ] Accessibility checks included

## Step 5: Generate Test Files

Output complete, ready-to-run test files:

**For Backend:**
- Create files in appropriate test package matching source structure
- Include all necessary imports and annotations
- Add setup/teardown methods if needed
- Reference existing test utilities

**For Frontend:**
- Create `.spec.ts` files in `/tests/e2e/`
- Use existing fixtures and page object patterns
- Configure multi-browser/viewport as needed
- Include visual regression baseline screenshots

## Output Format

```markdown
## Test Coverage Report

### Files Generated:
- `backend/src/test/java/com/threeriversbank/{package}/{Class}Test.java`
- `tests/e2e/{feature}.spec.ts`

### Coverage Summary:
- **Scenarios Covered:** {count}
- **Happy Paths:** {count}
- **Edge Cases:** {count}
- **Error Handling:** {count}

### Test Execution:
**Backend:** `cd backend && mvn test`
**Frontend:** `cd tests && npx playwright test`

### Next Steps:
1. Review generated test files
2. Run tests locally to verify
3. Add to CI/CD pipeline if not already included
```

## Three Rivers Bank Specific Considerations

**H2 Database Testing:**
- Tests must verify preloaded card data (5 cards from `data.sql`)
- Validate fee schedules and interest rates from H2
- Test card filtering (by type, annual fee, APR)

**BIAN API Integration Testing:**
- Mock BIAN API responses with WireMock
- Test circuit breaker scenarios (API unavailable → H2 fallback)
- Verify retry logic (3 attempts, 5s timeout)
- Test caching (transactions 5min TTL, billing 1hr TTL)

**Frontend Component Testing:**
- Test card comparison table with filters
- Verify card detail page displays fees and interest correctly
- Test responsive design across viewports
- Validate Material-UI Three Rivers Bank theme (navy/teal)

**Security Test Cases:**
- Input validation for card IDs (prevent injection)
- URL parameter sanitization
- API error response sanitization (no stack traces exposed)
- XSS prevention in card descriptions
