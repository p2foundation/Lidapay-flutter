# API Endpoint Configuration Check

## Current Configuration

The app is configured to use:
- **Base URL**: `https://api.advansistechnologies.com`
- **API Version**: `/api`
- **Login Endpoint**: `POST /api/auth/login`

**Full URL**: `https://api.advansistechnologies.com/api/auth/login`

## 404 Error Troubleshooting

If you're getting a 404 error, it means the endpoint doesn't exist at that path. Here are the possible causes:

### 1. Check API Documentation
Visit your API documentation at: https://api.advansistechnologies.com/api-doc

Verify:
- The actual endpoint path for login
- Whether it's `/api/auth/login` or `/auth/login` or something else
- The HTTP method (should be POST)

### 2. Common Endpoint Variations

The endpoint might be:
- `/auth/login` (without `/api` prefix)
- `/api/v1/auth/login` (with version)
- `/users/login` (different path structure)

### 3. Update Endpoint Configuration

If the endpoint path is different, update it in:
- `lib/data/datasources/api_client.dart` - Change the `@POST` annotation
- `lib/core/constants/app_constants.dart` - Update `apiVersion` if needed

### Example Fix

If your actual endpoint is `/auth/login` (without `/api`), change:

```dart
// In api_client.dart
@POST('/auth/login')  // Remove ${AppConstants.apiVersion}
Future<AuthResponse> login(@Body() LoginRequest request);
```

Or if it's `/api/v1/auth/login`:

```dart
// In app_constants.dart
static const String apiVersion = '/api/v1';
```

### 4. Test Endpoint Directly

Use a tool like Postman or curl to test:

```bash
curl -X POST https://api.advansistechnologies.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"0244588584","password":"yourpassword"}'
```

This will help you verify:
- If the endpoint exists
- What the correct path is
- What the expected request format is

### 5. Check Server Status

Make sure:
- The API server is running
- The base URL is correct
- There are no CORS issues (for web)

## Next Steps

1. Check your API documentation at https://api.advansistechnologies.com/api-doc
2. Verify the exact endpoint path
3. Update the configuration files accordingly
4. Regenerate code if needed: `flutter pub run build_runner build --delete-conflicting-outputs`

