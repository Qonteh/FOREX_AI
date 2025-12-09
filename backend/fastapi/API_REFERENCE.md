# API Endpoint Reference

## Quick Reference

### Base URL
```
http://localhost:8000
```

### Interactive Documentation
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

---

## Authentication Endpoints

All endpoints under `/auth`

### 1. Register User
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123",
  "referral_code": "FRIEND123"  // Optional
}
```

**Response (201)**
```json
{
  "id": 1,
  "email": "user@example.com",
  "is_active": true,
  "created_at": "2025-12-09T22:00:00Z"
}
```

---

### 2. Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123"
}
```

**Response (200)**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}
```

**Usage:**
```bash
# Save tokens
export ACCESS_TOKEN="eyJhbGciOiJIUzI1NiIs..."
export REFRESH_TOKEN="eyJhbGciOiJIUzI1NiIs..."

# Use access token in requests
curl -H "Authorization: Bearer $ACCESS_TOKEN" http://localhost:8000/auth/me
```

---

### 3. Refresh Token (with Rotation & Reuse Detection)
```http
POST /auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response (200)** - New tokens issued, old refresh token revoked
```json
{
  "access_token": "NEW_ACCESS_TOKEN",
  "refresh_token": "NEW_REFRESH_TOKEN",
  "token_type": "bearer"
}
```

**Security Response (401)** - If reuse detected
```json
{
  "detail": "Token reuse detected. All tokens have been revoked for security."
}
```
> ⚠️ All user tokens revoked when old token reused

---

### 4. Get Current User
```http
GET /auth/me
Authorization: Bearer {access_token}
```

**Response (200)**
```json
{
  "id": 1,
  "email": "user@example.com",
  "is_active": true,
  "created_at": "2025-12-09T22:00:00Z"
}
```

---

### 5. Logout (Single Device)
```http
POST /auth/logout
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response (200)**
```json
{
  "message": "Successfully logged out"
}
```

---

### 6. Logout All Devices
```http
POST /auth/logout_all
Authorization: Bearer {access_token}
```

**Response (200)**
```json
{
  "message": "Successfully logged out from all devices. Revoked 3 refresh tokens."
}
```

---

## Affiliate Endpoints

All endpoints under `/affiliates` - **Require Authentication**

### 1. Create Affiliate Code
```http
POST /affiliates/create
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "code": "MYCODE123"
}
```

**Response (201)**
```json
{
  "id": 1,
  "user_id": 1,
  "code": "MYCODE123",
  "created_at": "2025-12-09T22:00:00Z"
}
```

---

### 2. Get My Affiliate
```http
GET /affiliates/me
Authorization: Bearer {access_token}
```

**Response (200)**
```json
{
  "id": 1,
  "user_id": 1,
  "code": "MYCODE123",
  "created_at": "2025-12-09T22:00:00Z"
}
```

---

### 3. Get Affiliate Statistics
```http
GET /affiliates/stats
Authorization: Bearer {access_token}
```

**Response (200)**
```json
{
  "code": "MYCODE123",
  "total_referrals": 5,
  "total_commission": 0.0
}
```

---

## Wallet Endpoints

All endpoints under `/wallet` - **Require Authentication**

### 1. Get Balance
```http
GET /wallet/balance
Authorization: Bearer {access_token}
```

**Response (200)**
```json
{
  "id": 1,
  "user_id": 1,
  "balance": 1000.50
}
```

---

### 2. Deposit Funds
```http
POST /wallet/deposit
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "amount": 100.00,
  "description": "Initial deposit"  // Optional
}
```

**Response (201)**
```json
{
  "id": 1,
  "wallet_id": 1,
  "amount": 100.00,
  "type": "deposit",
  "description": "Initial deposit",
  "created_at": "2025-12-09T22:00:00Z"
}
```

---

### 3. Withdraw Funds
```http
POST /wallet/withdraw
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "amount": 50.00,
  "description": "ATM withdrawal"  // Optional
}
```

**Response (201)**
```json
{
  "id": 2,
  "wallet_id": 1,
  "amount": 50.00,
  "type": "withdraw",
  "description": "ATM withdrawal",
  "created_at": "2025-12-09T22:00:00Z"
}
```

**Error (400)** - Insufficient balance
```json
{
  "detail": "Insufficient balance"
}
```

---

### 4. Get Transaction History
```http
GET /wallet/transactions
Authorization: Bearer {access_token}
```

**Response (200)**
```json
[
  {
    "id": 2,
    "wallet_id": 1,
    "amount": 50.00,
    "type": "withdraw",
    "description": "ATM withdrawal",
    "created_at": "2025-12-09T22:00:00Z"
  },
  {
    "id": 1,
    "wallet_id": 1,
    "amount": 100.00,
    "type": "deposit",
    "description": "Initial deposit",
    "created_at": "2025-12-09T22:00:00Z"
  }
]
```
> ℹ️ Sorted by most recent first

---

## Error Responses

### 400 Bad Request
```json
{
  "detail": "Email already registered"
}
```

### 401 Unauthorized
```json
{
  "detail": "Could not validate credentials"
}
```

### 403 Forbidden
```json
{
  "detail": "User account is inactive"
}
```

### 404 Not Found
```json
{
  "detail": "User does not have an affiliate code"
}
```

---

## Common Use Cases

### Complete User Flow
```bash
# 1. Register
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'

# 2. Login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'
# Save tokens from response

# 3. Get profile
curl http://localhost:8000/auth/me \
  -H "Authorization: Bearer ACCESS_TOKEN"

# 4. Create affiliate code
curl -X POST http://localhost:8000/affiliates/create \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"code": "MYCODE"}'

# 5. Deposit money
curl -X POST http://localhost:8000/wallet/deposit \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000, "description": "Initial deposit"}'

# 6. Check balance
curl http://localhost:8000/wallet/balance \
  -H "Authorization: Bearer ACCESS_TOKEN"

# 7. Withdraw money
curl -X POST http://localhost:8000/wallet/withdraw \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 100, "description": "Withdrawal"}'

# 8. View transactions
curl http://localhost:8000/wallet/transactions \
  -H "Authorization: Bearer ACCESS_TOKEN"

# 9. Logout
curl -X POST http://localhost:8000/auth/logout \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "REFRESH_TOKEN"}'
```

---

## Token Security Testing

### Test Rotation
```bash
# 1. Login and save tokens
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}')

OLD_REFRESH=$(echo $LOGIN_RESPONSE | jq -r '.refresh_token')

# 2. Refresh once (normal flow)
NEW_TOKENS=$(curl -s -X POST http://localhost:8000/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\": \"$OLD_REFRESH\"}")

# 3. Try to reuse old token (should fail)
curl -X POST http://localhost:8000/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\": \"$OLD_REFRESH\"}"

# Expected: 401 with "Token reuse detected" message
```

---

## Notes

### Token Lifetimes
- **Access Token**: 30 minutes (for API requests)
- **Refresh Token**: 30 days (for getting new access tokens)

### Security Features
- ✅ Token rotation on refresh
- ✅ Reuse detection (revokes all tokens)
- ✅ Access token revocation
- ✅ Multiple logout options
- ✅ Password hashing with bcrypt

### Best Practices
1. Store access tokens in memory
2. Store refresh tokens securely (e.g., httpOnly cookies)
3. Always use HTTPS in production
4. Implement rate limiting for authentication endpoints
5. Monitor for suspicious activity (multiple failed logins, token reuse)

---

## Health Check

```http
GET /health
```

**Response (200)**
```json
{
  "status": "healthy"
}
```

---

For more details, see:
- README.md - Full setup guide
- IMPLEMENTATION_SUMMARY.md - Technical details
- test_security.py - Security feature demonstrations
