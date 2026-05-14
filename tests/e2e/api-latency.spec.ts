import { test, expect } from '@playwright/test';

const API_BASE_URL = 'http://localhost:8080';
const API_RESPONSE_TIME_SLO_MS = 2000;

test.describe('API Latency SLO', () => {
  test('GET /api/cards should respond within 2 seconds', async ({ request }) => {
    const start = Date.now();
    const response = await request.get(`${API_BASE_URL}/api/cards`);
    const elapsed = Date.now() - start;

    expect(response.ok()).toBeTruthy();
    expect(elapsed).toBeLessThan(API_RESPONSE_TIME_SLO_MS);
  });

  test('GET /api/cards page should load within 2 seconds', async ({ page }) => {
    const start = Date.now();
    await page.goto('/cards');
    await page.waitForLoadState('networkidle');
    const elapsed = Date.now() - start;

    await expect(page.locator('text=Business Cash Rewards')).toBeVisible();
    expect(elapsed).toBeLessThan(API_RESPONSE_TIME_SLO_MS);
  });
});
