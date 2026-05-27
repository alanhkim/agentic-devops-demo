---
description: "Security vulnerability review for Three Rivers Bank credit card website. Use when reviewing code for security issues, analyzing vulnerabilities, checking for XSS/CSRF, validating input sanitization, reviewing API security, or conducting security audits. Automatically applies to backend and frontend code changes."
applyTo: "**/*.{java,jsx,js,ts,tsx}"
---
# Security Review Guidelines - Three Rivers Bank

Automated security review for credit card comparison platform with focus on frontend XSS/CSRF, API integration security, and data exposure prevention.

## Review Workflow

When reviewing code changes, systematically check:

1. **Frontend Security (PRIMARY FOCUS)** - XSS, CSRF, client-side validation
2. **API Integration Security** - BIAN API calls, circuit breakers, error exposure
3. **Data Exposure** - Credit card product data, customer information handling
4. **Input/Output Validation** - User inputs, API responses, URL parameters

## 1. Frontend Security (React)

### XSS Prevention

**ALWAYS use React's built-in escaping:**
```jsx
// ✅ SAFE - React escapes by default
<div>{cardName}</div>
<div>{userInput}</div>

// ❌ VULNERABLE - dangerouslySetInnerHTML without sanitization
<div dangerouslySetInnerHTML={{__html: userInput}} />

// ⚠️ IF NEEDED - Use DOMPurify
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{
  __html: DOMPurify.sanitize(trustedHtml)
}} />
```

**URL Parameter Handling:**
```javascript
// ❌ VULNERABLE - Direct URL parameter usage
const cardId = window.location.search.split('=')[1];
navigate(`/cards/${cardId}`);

// ✅ SAFE - Validate and sanitize
import { useParams } from 'react-router-dom';
const { cardId } = useParams();
if (!/^[0-9]+$/.test(cardId)) {
  navigate('/error');
  return;
}
```

**API Response Rendering:**
```javascript
// ❌ VULNERABLE - Rendering unvalidated API response
<div>{apiResponse.description}</div>

// ✅ SAFE - Validate structure and sanitize
const safeDescription = typeof apiResponse.description === 'string' 
  ? apiResponse.description.substring(0, 500) 
  : 'No description available';
<div>{safeDescription}</div>
```

### CSRF Protection

**For this READ-ONLY API project, CSRF risk is minimal**, but validate if state-changing operations are added:

```javascript
// ⚠️ IF ADDING MUTATIONS - Check CSRF token
// This project is currently read-only, monitor for scope changes
const handleSubmit = async (data) => {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  if (!csrfToken) throw new Error('CSRF token missing');
  
  await fetch('/api/action', {
    method: 'POST',
    headers: { 'X-CSRF-Token': csrfToken },
    body: JSON.stringify(data)
  });
};
```

## 2. API Integration Security

### BIAN API Call Validation

**Always validate external API responses:**
```java
// ❌ VULNERABLE - Trusting external API without validation
public Transaction getTransaction(String id) {
    return bianApiClient.getTransaction(id); // Direct passthrough
}

// ✅ SAFE - Validate and sanitize
public Transaction getTransaction(String id) {
    if (!id.matches("^[A-Za-z0-9-]+$")) {
        throw new ValidationException("Invalid transaction ID");
    }
    
    Transaction tx = bianApiClient.getTransaction(id);
    
    // Validate critical fields exist and are safe
    if (tx.getAmount() == null || tx.getAmount() < 0) {
        throw new DataIntegrityException("Invalid transaction amount");
    }
    
    return sanitizeTransaction(tx);
}
```

### Circuit Breaker Error Handling

**Never expose internal errors to frontend:**
```java
// ❌ VULNERABLE - Leaking implementation details
@ControllerAdvice
public class ErrorHandler {
    @ExceptionHandler(BianApiException.class)
    public ResponseEntity<String> handle(BianApiException e) {
        return ResponseEntity.status(500).body(e.getMessage()); // Exposes stack traces
    }
}

// ✅ SAFE - Generic error with logging
@ControllerAdvice
public class ErrorHandler {
    @ExceptionHandler(BianApiException.class)
    public ResponseEntity<ErrorResponse> handle(BianApiException e) {
        logger.error("BIAN API error", e); // Log internally
        return ResponseEntity.status(503)
            .body(new ErrorResponse("Service temporarily unavailable"));
    }
}
```

## 3. Data Exposure Prevention

### Credit Card Product Data

**This project displays credit card PRODUCTS (not customer card numbers)**, but still validate data exposure:

```java
// ✅ SAFE - Product catalog data (fees, APR, features)
@GetMapping("/api/cards/{id}")
public CreditCardDTO getCard(@PathVariable Long id) {
    return cardService.getCardById(id); // Public product info OK
}

// ⚠️ MONITOR - Ensure no PII or sensitive data in responses
// Check DTOs don't accidentally include internal fields
@JsonIgnoreProperties({"internalCost", "profitMargin", "targetSegment"})
public class CreditCardDTO {
    // Only public-facing product details
}
```

### Frontend State Management

```javascript
// ❌ VULNERABLE - Storing sensitive data in localStorage
localStorage.setItem('userData', JSON.stringify(userData));

// ✅ SAFE - Use session storage for temporary data, avoid sensitive info
// This project has no auth, but monitor for scope creep
sessionStorage.setItem('selectedCards', JSON.stringify(cardIds));
```

## 4. Input Validation

### Backend Validation (Spring Boot)

```java
// ✅ REQUIRED - Validate all inputs
@GetMapping("/api/cards")
public List<CreditCardDTO> getCards(
    @RequestParam(required = false) String category
) {
    if (category != null) {
        // Whitelist allowed values
        if (!List.of("business", "personal", "premium").contains(category)) {
            throw new ValidationException("Invalid category");
        }
    }
    return cardService.getCards(category);
}

// ✅ Use Bean Validation
public class CardFilterRequest {
    @Pattern(regexp = "^[a-z]+$", message = "Invalid category format")
    @Size(max = 50)
    private String category;
    
    @Min(0) @Max(100000)
    private BigDecimal maxAnnualFee;
}
```

### Frontend Validation

```javascript
// ✅ Validate before API calls
const validateCardId = (id) => {
  if (!id || typeof id !== 'string') return false;
  if (!/^\d+$/.test(id)) return false;
  const numId = parseInt(id, 10);
  return numId > 0 && numId <= 99999;
};

const fetchCard = async (cardId) => {
  if (!validateCardId(cardId)) {
    throw new Error('Invalid card ID');
  }
  return api.get(`/api/cards/${cardId}`);
};
```

## 5. Configuration & Secrets

### Environment Variables

```javascript
// ❌ VULNERABLE - Exposing backend URL patterns
const API_URL = 'http://localhost:8080/api/cards';

// ✅ SAFE - Use environment variables
const API_URL = import.meta.env.VITE_API_BASE_URL || '/api';
```

```java
// ✅ SAFE - Never commit secrets, use environment variables
@Value("${bian.api.base-url}")
private String bianApiBaseUrl;

// ⚠️ VERIFY - H2 console disabled in production
@Configuration
public class H2ConsoleConfig {
    @Value("${spring.h2.console.enabled:false}")
    private boolean h2ConsoleEnabled;
    
    @PostConstruct
    public void validateConfig() {
        if (h2ConsoleEnabled && !isDevEnvironment()) {
            throw new IllegalStateException("H2 console must be disabled in production");
        }
    }
}
```

## Security Review Checklist

When reviewing code, verify:

- [ ] **No XSS vulnerabilities** - All user inputs and API responses properly escaped
- [ ] **URL parameters validated** - Card IDs, filters, pagination params sanitized
- [ ] **API errors sanitized** - No stack traces or internal details exposed
- [ ] **External API responses validated** - BIAN API data structure checked
- [ ] **No sensitive data in logs** - Remove PII before logging
- [ ] **Environment variables used** - No hardcoded URLs or secrets
- [ ] **H2 console disabled** - Verify production config
- [ ] **Input validation on both sides** - Backend (authoritative) + Frontend (UX)
- [ ] **Circuit breaker configured** - BIAN API calls have fallback

## Reference Patterns

For deeper security reviews, consult **enterprise-architect.agent.md** for:
- OWASP Top 10 detailed patterns
- Zero Trust implementation
- AI/LLM security (if integrating AI features)
- Cryptographic best practices

## Three Rivers Bank-Specific Context

This is a **read-only, public-facing product catalog** without authentication:
- ✅ No user accounts or login
- ✅ No payment processing
- ✅ No customer card numbers or PII
- ⚠️ Still validate to prevent XSS injection in product descriptions
- ⚠️ Monitor for scope changes (user accounts, payment features)

**If requirements change to include authentication or payment processing, escalate to full OWASP review.**
