# Authentication System - Complete ✅

## Updated to Match Your API Documentation

All authentication endpoints have been updated to match your NestJS backend API at `https://api.advansistechnologies.com/api-doc`.

### ✅ Changes Made

1. **API Version Updated**
   - Changed from `/api` to `/api/v1` to match your backend

2. **Login Endpoint**
   - **Path**: `POST /api/v1/users/login`
   - **Request**: Uses `username` (phone number) instead of `phone`
   - **Response**: Direct `accessToken` and `refreshToken` (no wrapper)

3. **Registration Endpoint** ✨ NEW
   - **Path**: `POST /api/v1/users/register`
   - **Request Fields**:
     - `firstName`
     - `lastName`
     - `email`
     - `phoneNumber`
     - `password`
     - `country`
     - `roles` (defaults to `['user']`)
     - `referrerClientId` (optional)

4. **User Profile Endpoints** ✨ NEW
   - **Get Profile**: `GET /api/v1/users/profile`
   - **Update Profile**: `PUT /api/v1/users/profile`
   - **Change Password**: `POST /api/v1/users/change-password`

5. **Refresh Token**
   - **Path**: `POST /api/v1/auth/refresh`
   - Returns new `accessToken` and `refreshToken`

## 📁 Updated Files

### Models (`lib/data/models/api_models.dart`)
- ✅ `LoginRequest` - Now uses `username` field
- ✅ `RegisterRequest` - New model with all registration fields
- ✅ `LoginResponse` - Direct tokens (accessToken, refreshToken)
- ✅ `RegisterResponse` - Registration response
- ✅ `RefreshTokenResponse` - Token refresh response
- ✅ `User` - Updated with all fields (phoneNumber, country, roles, etc.)
- ✅ `UpdateProfileRequest` - Profile update model
- ✅ `UserProfileResponse` - Profile response
- ✅ `ChangePasswordRequest` - Password change model

### API Client (`lib/data/datasources/api_client.dart`)
- ✅ Updated all endpoints to use `/api/v1`
- ✅ Login endpoint: `/api/v1/users/login`
- ✅ Register endpoint: `/api/v1/users/register`
- ✅ Profile endpoints added
- ✅ Change password endpoint added

### Repository (`lib/data/repositories/auth_repository.dart`)
- ✅ `register()` - New registration method
- ✅ `login()` - Updated to use `username` and handle direct token response
- ✅ `refreshToken()` - Updated to handle new response format
- ✅ `getUserProfile()` - New method
- ✅ `updateUserProfile()` - New method
- ✅ `changePassword()` - New method

### Providers (`lib/presentation/providers/auth_provider.dart`)
- ✅ Updated `AuthNotifier` to handle new response structure
- ✅ Added `register()` method
- ✅ `currentUserProvider` now fetches from profile endpoint

### UI Screens
- ✅ `login_screen.dart` - Updated to use `username`
- ✅ `register_screen.dart` - ✨ NEW registration screen
- ✅ `profile_screen.dart` - Updated to use profile endpoint
- ✅ Router updated with registration route

## 🔐 Authentication Flow

### Registration
1. User fills registration form
2. Calls `POST /api/v1/users/register`
3. On success, redirects to login

### Login
1. User enters username (phone) and password
2. Calls `POST /api/v1/users/login`
3. Receives `accessToken` and `refreshToken`
4. Tokens saved to SharedPreferences
5. Redirects to dashboard

### Token Refresh
1. When `accessToken` expires
2. Calls `POST /api/v1/auth/refresh` with `refreshToken`
3. Receives new tokens
4. Updates stored tokens

### Profile Management
1. **Get Profile**: Fetches user data from `/api/v1/users/profile`
2. **Update Profile**: Updates user info via `/api/v1/users/profile`
3. **Change Password**: Changes password via `/api/v1/users/change-password`

## 🎯 Key Features

- ✅ Registration with full user details
- ✅ Login with username (phone number)
- ✅ Automatic token refresh
- ✅ User profile management
- ✅ Password change functionality
- ✅ Proper error handling for all endpoints
- ✅ Token storage and management

## 📝 Next Steps

1. **Test Registration**: Try creating a new account
2. **Test Login**: Login with registered credentials
3. **Test Profile**: View and update user profile
4. **Test Password Change**: Change password functionality

All authentication endpoints are now perfectly aligned with your NestJS backend API! 🎉

