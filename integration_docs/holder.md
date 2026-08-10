# Holder Management API (aviv2)

This document describes the API endpoints for managing joint account holders in the Pivot Money system.

## Authentication
All endpoints require a valid JWT Access Token in the `Authorization` header.
`Authorization: Bearer <access_token>`

---

## 1. List Holders
Fetch all joint holders associated with the authenticated user.

*   **URL:** `/api/v2/profile/holders/`
*   **Method:** `GET`
*   **Success Response:**
    *   **Status:** 200 OK
    *   **Payload:**
        ```json
        {
          "success": true,
          "data": {
            "holders": [
              {
                "id": 1,
                "name": "John Doe",
                "pan_number": "ABCDE1234F",
                "dob": "1990-01-01",
                "tin": null,
                "investor_residency": "Resident",
                "email": "john@example.com",
                "phone_number": "9876543210",
                "father_name": "Senior Doe",
                "gender": "M",
                "address": {},
                "masked_aadhaar": "XXXXXXXX1234",
                "aadhaar_linked": true,
                "is_verified": true,
                "has_signature": false,
                "created_at": "2024-04-20T10:00:00Z",
                "updated_at": "2024-04-20T10:00:00Z"
              }
            ],
            "count": 1
          }
        }
        ```

---

## 2. Add Holder (Verification)
Add a new holder by providing their PAN. The backend will verify the PAN against income tax records (via bureau or internal cache) and create a holder record.

*   **URL:** `/api/v2/profile/holders/`
*   **Method:** `POST`
*   **Payload:**
    ```json
    {
      "pan_number": "ABCDE1234F"
    }
    ```
*   **Success Response:**
    *   **Status:** 200 OK
    *   **Payload:** Same as **List Holders** (returns the created/updated holder object in `data.holder`).
*   **Errors:**
    *   `400`: Invalid PAN format or same as primary user.
    *   `502`: PAN verification failed (bureau error).

---

## 3. Get Holder Detail
Fetch details of a specific holder.

*   **URL:** `/api/v2/profile/holders/<id>/`
*   **Method:** `GET`
*   **Success Response:**
    *   **Status:** 200 OK
    *   **Payload:**
        ```json
        {
          "success": true,
          "data": {
            "holder": { ... }
          }
        }
        ```

---

## 4. Update Holder
Update editable information for a holder.

*   **URL:** `/api/v2/profile/holders/<id>/`
*   **Method:** `PATCH`
*   **Payload (all fields optional):**
    ```json
    {
      "name": "John Updated Doe",
      "email": "newemail@example.com",
      "phone_number": "9988776655",
      "dob": "1990-01-01",
      "tin": "TAX123456",
      "investor_residency": "Resident", 
      "gender": "M",
      "father_name": "Father Name",
      "address": {
        "address_line_1": "123 Main St",
        "city": "Mumbai",
        "pincode": "400001"
      },
      "signature": "data:image/png;base64,..."
    }
    ```
    *   `investor_residency` must be one of: `Resident`, `NRI-NRE`, `NRI-NRO`.
    *   `gender` should be `M`, `F`, or `O`.
    *   `signature` should be a base64 encoded PNG (minimum 80 chars).

*   **Success Response:**
    *   **Status:** 200 OK
    *   **Payload:** Returns updated holder object.

---

## 5. Remove Holder
Delete a holder record from the user's profile.

*   **URL:** `/api/v2/profile/holders/<id>/`
*   **Method:** `DELETE`
*   **Success Response:**
    *   **Status:** 200 OK
    *   **Payload:**
        ```json
        {
          "success": true,
          "message": "Holder removed.",
          "data": {}
        }
        ```
