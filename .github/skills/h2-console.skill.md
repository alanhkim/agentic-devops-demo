---
name: "h2-console"
description: "Access and use the H2 in-memory database console for debugging"
applyTo: ["**/data.sql", "**/*.java"]
"trigger phrases": ["h2 console", "database console", "check database", "inspect h2", "view database data"]
---

# H2 Console Quick Reference

Use this reference to quickly inspect database state for the Three Rivers Bank backend.

## 1) Access The Console

1. Start the backend service.
2. Open the H2 console in your browser:
   - `http://localhost:8080/h2-console`
3. Use connection settings from `backend/src/main/resources/application.yml`.

Default local dev values used by this project:
- JDBC URL: `jdbc:h2:mem:creditcards`
- User Name: `sa`
- Password: *(leave blank)*

## 2) Critical Connection Details

- JDBC URL must match exactly: `jdbc:h2:mem:creditcards`
- User: `sa`
- Password: none (empty)
- H2 is in-memory, so data resets when the app restarts unless reseeded.

## 3) Useful Queries For The 5 Preloaded Credit Cards

Run these in the H2 SQL editor after connecting.

```sql
-- List all preloaded cards
SELECT id, name, card_type, annual_fee
FROM credit_card
ORDER BY id;
```

```sql
-- Count cards (expected: 5)
SELECT COUNT(*) AS card_count
FROM credit_card;
```

```sql
-- Features per card
SELECT cc.id, cc.name, cf.feature_name
FROM credit_card cc
LEFT JOIN card_feature cf ON cf.credit_card_id = cc.id
ORDER BY cc.id, cf.feature_name;
```

```sql
-- Fee schedules per card
SELECT cc.id, cc.name, fs.fee_type, fs.amount
FROM credit_card cc
LEFT JOIN fee_schedule fs ON fs.credit_card_id = cc.id
ORDER BY cc.id, fs.fee_type;
```

```sql
-- Interest rates per card
SELECT cc.id, cc.name, ir.rate_type, ir.apr
FROM credit_card cc
LEFT JOIN interest_rate ir ON ir.credit_card_id = cc.id
ORDER BY cc.id, ir.rate_type;
```

## 4) Verify Seed Data Loaded Correctly

Use this checklist:
1. `SELECT COUNT(*) FROM credit_card;` returns `5`.
2. Card names include:
   - Business Cash Rewards
   - Business Travel Rewards
   - Business Platinum
   - Business Premium
   - Business Flex
3. Related tables (`card_feature`, `fee_schedule`, `interest_rate`) return rows linked by `credit_card_id`.
4. Application startup logs do not show SQL/data initialization errors.

If counts are wrong, restart backend and confirm `data.sql` exists at `backend/src/main/resources/data.sql`.

## 5) Production Safety Warning

H2 console should be disabled in production:
- `SPRING_H2_CONSOLE_ENABLED=false`

Do not expose H2 console publicly in deployed environments.

## 6) Troubleshooting Console Access

- 404 on `/h2-console`:
  - Confirm backend is running on port `8080`.
  - Verify H2 console is enabled in configuration.
- Login fails:
  - Re-check JDBC URL, user, and blank password.
  - Ensure URL is `jdbc:h2:mem:creditcards` (no typos).
- Empty tables:
  - You may be connected to a different in-memory DB URL.
  - Restart app to re-run `data.sql`.
- Table not found:
  - Check exact table names and casing in the SQL query.
  - Confirm schema creation and seed scripts completed at startup.
