# Authentication & Profile API Verification

## ✅ Login Endpoint

### Endpoint
`POST /api/v1/users/login`

### Request Body
```json
{
  "username": "0123456789",
  "password": "securePassword123"
}
```

### Expected Response (201 Created)
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "673ba0e3f2c001e4dcee976e",
    "username": "Crayman",
    "firstName": "Crayman",
    "lastName": "Holmes",
    "email": "pp.craman@outlook.com",
    "phoneNumber": "0593998216",
    "password": "$2b$10$...",
    "gravatar": "data:image/png;base64,..."
  }
}
```

### Implementation Status
✅ **Request Model**: `LoginRequest` with `username` and `password`
✅ **Response Model**: `LoginResponse` with `access_token`, `refresh_token`, and `user`
✅ **Status Code**: Handles 201 Created (Dio/Retrofit handles this automatically)
✅ **Token Storage**: Tokens saved to SharedPreferences
✅ **User Storage**: User ID saved for reference

### Code Location
- Model: `lib/data/models/api_models.dart` - `LoginRequest`, `LoginResponse`
- Repository: `lib/data/repositories/auth_repository.dart` - `login()` method
- API Client: `lib/data/datasources/api_client.dart` - `login()` endpoint

---

## ✅ Get Profile Endpoint

### Endpoint
`GET /api/v1/users/profile`

### Headers Required
```
Authorization: Bearer {access_token}
```

### Expected Response (200 OK)
```json
{
  "_id": "673ba0e3f2c001e4dcee976e",
  "username": "Crayman",
  "firstName": "Crayman",
  "lastName": "Holmes",
  "email": "pp.craman@outlook.com",
  "phoneNumber": "0593998216",
  "password": "$2b$10$...",
  "gravatar": "data:image/png;base64,..."
}
```

**Note**: The API returns the user object directly (not wrapped in a `user` field).

### Implementation Status
✅ **Bearer Token**: Automatically added via `AuthInterceptor`
✅ **Response Model**: `UserProfileResponse` handles both wrapped and direct user object
✅ **Error Handling**: Handles 401 (unauthorized), 404 (not found), and network errors
✅ **Logging**: Comprehensive logging for debugging

### Code Location
- Model: `lib/data/models/api_models.dart` - `UserProfileResponse` (with flexible parsing)
- Repository: `lib/data/repositories/auth_repository.dart` - `getUserProfile()` method
- API Client: `lib/data/datasources/api_client.dart` - `getUserProfile()` endpoint
- Interceptor: `lib/data/datasources/api_client.dart` - `AuthInterceptor` adds Bearer token

---

## 🔧 Implementation Details

### Bearer Token Authentication
The `AuthInterceptor` automatically adds the Bearer token to all authenticated requests:

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

### User Profile Response Parsing
The `UserProfileResponse` model handles both response formats:

1. **Direct user object** (what the API actually returns):
   ```json
   { "_id": "...", "username": "...", ... }
   ```

2. **Wrapped user object** (fallback for consistency):
   ```json
   { "user": { "_id": "...", "username": "...", ... } }
   ```

### Error Handling
- **401 Unauthorized**: Token expired or invalid → User needs to login again
- **404 Not Found**: Profile doesn't exist → Show error message
- **Network Errors**: Connection issues → Show network error message
- **Other Errors**: Server errors → Show generic error with status code

---

## ✅ Testing Checklist

- [ ] Login with valid credentials → Should return tokens and user object
- [ ] Login with invalid credentials → Should return 401 error
- [ ] Get profile with valid token → Should return user object
- [ ] Get profile with invalid/expired token → Should return 401 error
- [ ] Get profile without token → Should return 401 error
- [ ] Verify tokens are saved after login
- [ ] Verify Bearer token is sent in Authorization header
- [ ] Verify user object is parsed correctly (direct format)

---

## 📝 Notes

1. **Status Code**: Login returns `201 Created`, not `200 OK`. Dio/Retrofit handles this automatically.

2. **Username Field**: The API uses `username` for login, which can be a phone number or email.

3. **User Object**: The API returns the user object directly in the profile endpoint, not wrapped in a `user` field.

4. **Gravatar**: The API returns a base64-encoded image in the `gravatar` field. This can be used directly in Flutter Image widgets.

5. **Password Field**: The API returns the hashed password in responses, but it should never be used or displayed in the app.

