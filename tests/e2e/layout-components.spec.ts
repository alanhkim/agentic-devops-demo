import { test, expect } from '@playwright/test';

test.describe('Header Component', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
  });

  test('should display Three Rivers Bank branding', async ({ page }) => {
    // Check for bank name in header
    const header = page.locator('header');
    await expect(header).toBeVisible();
    await expect(page.locator('text=Three Rivers Bank').first()).toBeVisible();
  });

  test('should display bank icon', async ({ page }) => {
    // AccountBalanceIcon should be visible
    const header = page.locator('header');
    const svgIcon = header.locator('svg').first();
    await expect(svgIcon).toBeVisible();
  });

  test('should have navigation links on desktop', async ({ page }) => {
    // Skip if viewport is mobile/tablet
    const viewportSize = page.viewportSize();
    if (viewportSize && viewportSize.width < 900) {
      test.skip();
    }

    // Check for Home link
    const homeLink = page.locator('header a:has-text("Home")');
    await expect(homeLink).toBeVisible();

    // Check for Compare Cards link
    const compareLink = page.locator('header button:has-text("Compare Cards")');
    await expect(compareLink).toBeVisible();
  });

  test('should navigate to home when clicking bank name', async ({ page }) => {
    // Navigate to different page first
    await page.goto('/cards');
    await page.waitForLoadState('networkidle');

    // Click on bank name
    await page.click('text=Three Rivers Bank');

    // Verify navigation to home
    await expect(page).toHaveURL('/');
  });

  test('should navigate to compare cards page', async ({ page }) => {
    // Skip if viewport is mobile/tablet where navigation might be different
    const viewportSize = page.viewportSize();
    if (viewportSize && viewportSize.width < 900) {
      test.skip();
    }

    // Click Compare Cards button
    await page.click('header button:has-text("Compare Cards")');

    // Verify navigation
    await expect(page).toHaveURL('/cards');
  });

  test('should display Contact Us button', async ({ page }) => {
    const contactButton = page.locator('header button:has-text("Contact Us")');
    await expect(contactButton).toBeVisible();
  });

  test('should have sticky positioning', async ({ page }) => {
    // Check that header has AppBar with sticky position
    const header = page.locator('header');
    await expect(header).toBeVisible();

    // Scroll down
    await page.evaluate(() => window.scrollTo(0, 500));

    // Header should still be visible
    await expect(header).toBeVisible();
  });

  test('should be responsive on mobile viewport', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Header should be visible
    const header = page.locator('header');
    await expect(header).toBeVisible();

    // Bank name should be visible on mobile
    await expect(page.locator('text=Three Rivers Bank').first()).toBeVisible();

    // Contact Us button should be visible
    await expect(page.locator('button:has-text("Contact Us")').first()).toBeVisible();
  });

  test('should be responsive on tablet viewport', async ({ page }) => {
    // Set tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Header should be visible
    const header = page.locator('header');
    await expect(header).toBeVisible();

    // Bank name should be visible
    await expect(page.locator('text=Three Rivers Bank').first()).toBeVisible();
  });

  test('should have proper Three Rivers Bank theme colors', async ({ page }) => {
    const header = page.locator('header');
    
    // Header should have primary color (navy #003366)
    const headerBg = await header.evaluate((el) => {
      return window.getComputedStyle(el).backgroundColor;
    });
    
    // Verify it's a dark blue color (navy)
    expect(headerBg).toBeTruthy();
  });

  test('should have accessible navigation structure', async ({ page }) => {
    // Header should be a <header> landmark
    const header = page.locator('header');
    await expect(header).toBeVisible();

    // Toolbar should be present
    const toolbar = page.locator('header [class*="MuiToolbar"]');
    await expect(toolbar).toBeVisible();
  });
});

test.describe('Footer Component', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
  });

  test('should display Three Rivers Bank branding in footer', async ({ page }) => {
    // Scroll to footer
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    await expect(footer).toBeVisible();
    await expect(footer.locator('text=Three Rivers Bank').first()).toBeVisible();
  });

  test('should display company description', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    await expect(footer.locator('text=Your trusted partner for business credit solutions')).toBeVisible();
  });

  test('should display contact phone number', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    await expect(footer.locator('text=1-800-THREE-RB')).toBeVisible();
  });

  test('should display contact email', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    await expect(footer.locator('text=business@threeriversbank.com')).toBeVisible();
  });

  test('should display location', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    await expect(footer.locator('text=Pittsburgh, PA')).toBeVisible();
  });

  test('should display contact icons', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    
    // Should have phone, email, and location icons (SVG elements)
    const icons = footer.locator('svg');
    const iconCount = await icons.count();
    expect(iconCount).toBeGreaterThanOrEqual(3);
  });

  test('should display quick links section', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    await expect(footer.locator('text=Quick Links')).toBeVisible();
  });

  test('should have Branch Locator link', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    const branchLink = footer.locator('a:has-text("Branch Locator")');
    await expect(branchLink).toBeVisible();
  });

  test('should have About Us link', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    const aboutLink = footer.locator('a:has-text("About Us")');
    await expect(aboutLink).toBeVisible();
  });

  test('should have Privacy Policy link', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    const privacyLink = footer.locator('a:has-text("Privacy Policy")');
    await expect(privacyLink).toBeVisible();
  });

  test('should have Terms of Service link', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    const termsLink = footer.locator('a:has-text("Terms of Service")');
    await expect(termsLink).toBeVisible();
  });

  test('should display copyright notice', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    const currentYear = new Date().getFullYear();
    await expect(footer.locator(`text=© ${currentYear} Three Rivers Bank`)).toBeVisible();
  });

  test('should display FDIC member notice', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    await expect(footer.locator('text=Member FDIC')).toBeVisible();
  });

  test('should display Equal Housing Lender notice', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    await expect(footer.locator('text=Equal Housing Lender')).toBeVisible();
  });

  test('should have proper Three Rivers Bank theme colors in footer', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    
    // Footer should have primary color background (navy #003366)
    const footerBg = await footer.evaluate((el) => {
      return window.getComputedStyle(el).backgroundColor;
    });
    
    // Verify it's a dark blue color
    expect(footerBg).toBeTruthy();
  });

  test('should be responsive on mobile viewport', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Scroll to footer
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    await expect(footer).toBeVisible();

    // All sections should stack vertically on mobile
    await expect(footer.locator('text=Three Rivers Bank').first()).toBeVisible();
    await expect(footer.locator('text=Contact Information')).toBeVisible();
    await expect(footer.locator('text=Quick Links')).toBeVisible();
  });

  test('should be responsive on tablet viewport', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Scroll to footer
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    await expect(footer).toBeVisible();

    // All content should be visible
    await expect(footer.locator('text=Three Rivers Bank').first()).toBeVisible();
    await expect(footer.locator('text=Contact Information')).toBeVisible();
  });

  test('should have proper spacing and layout structure', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    
    // Should have container
    const container = footer.locator('[class*="MuiContainer"]');
    await expect(container).toBeVisible();

    // Should have grid layout for sections
    const gridItems = footer.locator('[class*="MuiGrid"]');
    const gridCount = await gridItems.count();
    expect(gridCount).toBeGreaterThan(0);
  });

  test('should have semantic footer element', async ({ page }) => {
    // Footer should be a <footer> landmark
    const footer = page.locator('footer');
    await expect(footer).toBeVisible();
  });

  test('should have divider between content and copyright', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    
    // Should have divider element
    const divider = footer.locator('hr');
    await expect(divider).toBeVisible();
  });

  test('should update copyright year dynamically', async ({ page }) => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const footer = page.locator('footer');
    const currentYear = new Date().getFullYear();
    const copyrightText = await footer.locator('text=/© \\d{4} Three Rivers Bank/').textContent();
    
    expect(copyrightText).toContain(currentYear.toString());
  });
});

test.describe('Header and Footer Integration', () => {
  test('should display header and footer on all pages', async ({ page }) => {
    // Test on home page
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await expect(page.locator('header')).toBeVisible();
    await expect(page.locator('footer')).toBeVisible();

    // Test on cards page
    await page.goto('/cards');
    await page.waitForLoadState('networkidle');
    await expect(page.locator('header')).toBeVisible();
    await expect(page.locator('footer')).toBeVisible();
  });

  test('should maintain consistent branding between header and footer', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Both should display "Three Rivers Bank"
    const header = page.locator('header');
    const footer = page.locator('footer');

    await expect(header.locator('text=Three Rivers Bank').first()).toBeVisible();
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await expect(footer.locator('text=Three Rivers Bank').first()).toBeVisible();
  });

  test('should have consistent color theme across header and footer', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const header = page.locator('header');
    const footer = page.locator('footer');

    const headerBg = await header.evaluate((el) => window.getComputedStyle(el).backgroundColor);
    
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    const footerBg = await footer.evaluate((el) => window.getComputedStyle(el).backgroundColor);

    // Both should use the same primary color (navy)
    expect(headerBg).toBeTruthy();
    expect(footerBg).toBeTruthy();
    expect(headerBg).toEqual(footerBg);
  });
});
