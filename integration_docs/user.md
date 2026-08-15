# Auth API Documentation (v1)

This document provides instructions for frontend developers to integrate with the Pivot Money Authentication system.

## Base URL
`{{BACKEND_URL}}/api/v1/`

---

## 1. Login / Send OTP
Initiates the login process by sending a 6-digit OTP.

- **Endpoint:** `POST auth/login/`
- **Headers:** 
  - `Content-Type: application/json`
- **Payload:**
  ```json
  {
    "identifier": "9917691281"  // Phone number (10 digits) OR Email
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "success": true,
    "type": "phone", // or "email"
    "message": "OTP sent successfully"
  }
  ```

---

## 2. Verify OTP / Issue Tokens
Verifies the OTP and issues JWT tokens.

- **Endpoint:** `POST auth/verify/`
- **Headers:** 
  - `Content-Type: application/json`
- **Payload:**
  ```json
  {
    "identifier": "9917691281",
    "otp": "123456"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Login successful",
    "data": {
      "access": "ACCESS_TOKEN_STRING",
      "refresh": "REFRESH_TOKEN_STRING",
      "user": {
        "id": "uuid",
        "name": "User Name",
        "email": "user@example.com",
        "phone_number": "919917691281"
      }
    }
  }
  ```

---

## 3. Refresh Access Token
Get a new Access Token using your Refresh Token.

- **Endpoint:** `POST auth/refresh/`
- **Headers:** 
  - `Content-Type: application/json`
- **Payload:**
  ```json
  {
    "refresh_token": "YOUR_REFRESH_TOKEN"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "access_token": "NEW_ACCESS_TOKEN_STRING"
  }
  ```

---

## 4. Get Onboarding Status (Protected)
Tells you which screen to open next (PAN, Bank, etc.).

- **Endpoint:** `GET auth/status/`
- **Headers:** 
  - `Authorization: Bearer <access_token>`
- **Payload:** None (GET request)
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "status": "pan" // values: "pan", "bank", "profile", "order"
  }
  ```

---

### 🚦 Token Expiration & Error Handling

#### Case A: Access Token Expired
This happens during a regular API call (e.g., fetching status).
- **Status:** `401 Unauthorized`
- **Response Payload:**
  ```json
  {
      "detail": "Given token not valid for any token type",
      "code": "token_not_valid",
      "messages": [{"token_class": "AccessToken", "token_type": "access", "message": "Token is expired"}]
  }
  ```
- **Action:** Call `POST auth/refresh/` using your stored `refresh_token`.

#### Case B: Refresh Token Expired or Revoked
- **Status:** `401 Unauthorized`
- **Response Payload:**
  ```json
  {
      "success": false, 
      "message": "Refresh token expired, please login again"
  }
  ```
- **Action:** Clear all tokens from local storage and redirect the user to the **OTP Login Screen**.

---

## 🛠 Integration Rules

### 1. Token Usage
- **Access Token:** Send in the `Authorization` header for all protected routes:  
  `Authorization: Bearer <access_token>`
- **Refresh Token:** Store securely. Use it ONLY to call `/auth/refresh/`.

### 2. Phone Normalization
- The backend accepts any format but normalizes it to a clean 10-digit primary ID.
- Example: `+919917691281` $\rightarrow$ `9917691281`.
