# API Implementation Plan

Based on the API documentation at `api.advansistechnologies.com/api-doc`, we need to implement the following endpoints:

## 1. Authentication and Profile ✅ (Fully Implemented)

### Current Implementation:
- ✅ **Login**: `POST /api/v1/users/login`
  - Request: `username`, `password`
  - Response: `access_token`, `refresh_token`, `user` object
  - Status: 201 Created
- ✅ **Register**: `POST /api/v1/users/register`
  - Request: `firstName`, `lastName`, `email`, `phoneNumber`, `password`, `roles` (string), `country` (full name)
  - Response: User object
  - Error handling: Parses nested 409 Conflict errors
  - Account type mapping: user→USER, merchant→MERCHANT, agent→AGENT
- ✅ **Get Profile**: `GET /api/v1/users/profile`
  - Requires: Bearer token in Authorization header
  - Response: User object (direct, not wrapped)
- ✅ **Update Profile**: `PUT /api/v1/users/profile`
- ✅ **Change Password**: `POST /api/v1/users/change-password`
- ✅ **Refresh Token**: `POST /api/v1/auth/refresh`

### Implementation Details:
- ✅ Bearer token automatically added via `AuthInterceptor`
- ✅ Error handling for nested error structures
- ✅ Country mapper for code-to-name conversion
- ✅ Account type to role mapping in registration wizard

## 2. Airtime ⚠️ (Needs Verification)

### Current Implementation:
- ✅ Reloadly Global: `POST /api/v1/airtime/reloadly`
- ✅ Prymo Ghana: `POST /api/v1/airtime/prymo`

### To Verify/Update:
- [ ] Check actual endpoint paths from API docs
- [ ] Verify request body structure
- [ ] Verify response format
- [ ] Test airtime purchase flow
- [ ] Handle errors properly

## 3. Internet Data ⚠️ (Needs Verification)

### Current Implementation:
- ✅ Reloadly Global: `POST /api/v1/data/reloadly`
- ✅ Prymo Ghana: `POST /api/v1/data/prymo`

### To Verify/Update:
- [ ] Check actual endpoint paths from API docs
- [ ] Verify request body structure (dataAmount vs dataPlanId)
- [ ] Verify response format
- [ ] Test data purchase flow
- [ ] Handle errors properly

## 4. Payment ⚠️ (Needs Verification)

### Current Implementation:
- ✅ ExpressPay Initiate: `POST /api/v1/payment/expresspay/initiate`
- ✅ ExpressPay Verify: `POST /api/v1/payment/expresspay/verify`
- ✅ ExpressPay Methods: `GET /api/v1/payment/expresspay/methods`

### To Verify/Update:
- [ ] Check actual endpoint paths from API docs
- [ ] Verify payment flow
- [ ] Test payment initiation
- [ ] Test payment verification
- [ ] Handle payment errors

## 5. Transactions/History ✅ (With Fallback)

### Current Implementation:
- ✅ Get Transactions: `GET /api/v1/transactions`
- ✅ Get Transaction Detail: `GET /api/v1/transactions/{id}`
- ✅ **NEW**: Timeout handling (10 seconds)
- ✅ **NEW**: Fallback to empty data on timeout/failure
- ✅ **NEW**: Better error messages

### Query Parameters:
- `page` (default: 1)
- `pageSize` (default: 20)
- `type` (optional: airtime, data, transfer)
- `status` (optional: pending, completed, failed)
- `startDate` (optional: ISO 8601 format)
- `endDate` (optional: ISO 8601 format)

### Improvements Made:
1. **Timeout Protection**: 10-second timeout prevents indefinite loading
2. **Fallback Mechanism**: Returns empty transactions data instead of error
3. **Better UX**: Shows timeout message with retry button
4. **Reduced Dio Timeouts**: 15 seconds (down from 30) for faster failure detection

## Implementation Steps

### Step 1: Review API Documentation
Visit: `https://api.advansistechnologies.com/api-doc`

Verify:
- Actual endpoint paths
- Request/response formats
- Authentication requirements
- Error response formats

### Step 2: Update API Client
File: `lib/data/datasources/api_client.dart`

Update endpoints based on actual API documentation:
- Verify all endpoint paths
- Update request/response models if needed
- Add any missing endpoints

### Step 3: Update Models
File: `lib/data/models/api_models.dart`

Ensure models match API response structure:
- Add missing fields
- Update field types if needed
- Handle nullable fields properly

### Step 4: Test Each Endpoint
1. Authentication - Test login/register
2. Profile - Test get/update profile
3. Airtime - Test purchase flow
4. Data - Test purchase flow
5. Payment - Test payment flow
6. Transactions - Test listing and details

### Step 5: Error Handling
- Add proper error messages
- Handle network errors
- Handle API errors (400, 401, 404, 500)
- Show user-friendly messages

## Current Status

✅ **Transactions**: Fully implemented with timeout and fallback
⚠️ **Other Endpoints**: Need verification against API docs

## Next Actions

1. Review API documentation at `api.advansistechnologies.com/api-doc`
2. Update endpoint paths if different
3. Test each endpoint
4. Fix any issues found
5. Update error handling as needed

