# Register API Verification

## ✅ Register Endpoint

### Endpoint
`POST /api/v1/users/register`

### Request Body
```json
{
  "firstName": "Peprah",
  "lastName": "Crayman",
  "email": "pp.crayman@outlook.com",
  "phoneNumber": "0244588584",
  "password": "V9DTesfRBjgH",
  "roles": "AGENT",
  "country": "GHANA"
}
```

### Request Fields
- `firstName` (required): User's first name
- `lastName` (required): User's last name
- `email` (required): User's email address
- `phoneNumber` (required): User's phone number (without country code prefix)
- `password` (required): User's password
- `roles` (required): Account type as string - `"USER"`, `"MERCHANT"`, or `"AGENT"` (uppercase)
- `country` (required): Full country name like `"GHANA"`, `"NIGERIA"`, etc. (not country code)
- `referrerClientId` (optional): Referrer client ID if applicable

### Expected Success Response
```json
{
  "message": "Registration successful",
  "user": {
    "_id": "...",
    "username": "...",
    "firstName": "...",
    "lastName": "...",
    "email": "...",
    "phoneNumber": "...",
    ...
  }
}
```

### Error Response (409 Conflict)
```json
{
  "statusCode": 409,
  "timestamp": "2025-12-24T20:45:57.858Z",
  "path": "/api/v1/users/register",
  "message": {
    "message": "User with this email or phone number already exists",
    "error": "Conflict",
    "statusCode": 409
  }
}
```

### Implementation Status
✅ **Request Model**: `RegisterRequest` with all required fields
✅ **Roles**: String format (USER, MERCHANT, AGENT) - mapped from account type
✅ **Country**: Full country name (GHANA) - not country code
✅ **Error Handling**: Parses nested error structure from API
✅ **Account Type Mapping**: 
  - `user` → `"USER"`
  - `merchant` → `"MERCHANT"`
  - `agent` → `"AGENT"`

### Code Location
- Model: `lib/data/models/api_models.dart` - `RegisterRequest`
- Repository: `lib/data/repositories/auth_repository.dart` - `register()` method
- Provider: `lib/presentation/providers/auth_provider.dart` - `register()` method
- Screen: `lib/presentation/features/auth/screens/register_screen.dart` - Registration wizard

---

## 🔧 Implementation Details

### Account Type to Role Mapping
The registration wizard maps account types to API roles:

```dart
String? role;
switch (_selectedAccountType?.toLowerCase()) {
  case 'user':
    role = 'USER';
    break;
  case 'merchant':
    role = 'MERCHANT';
    break;
  case 'agent':
    role = 'AGENT';
    break;
  default:
    role = 'USER';
}
```

### Country Format
- **API Expects**: Full country name (e.g., `"GHANA"`, `"NIGERIA"`, `"KENYA"`)
- **Current Default**: `"GHANA"`
- **Note**: Country selector should return full country names, not codes

### Error Handling
The error response has a nested structure:
```json
{
  "message": {
    "message": "Actual error message here",
    "error": "Error type",
    "statusCode": 409
  }
}
```

The repository now parses this nested structure to extract the actual error message.

### Error Codes
- **400 Bad Request**: Invalid registration data
- **409 Conflict**: User already exists with email or phone number
- **500 Server Error**: Internal server error

---

## ✅ Testing Checklist

- [ ] Register with USER role → Should succeed
- [ ] Register with MERCHANT role → Should succeed
- [ ] Register with AGENT role → Should succeed
- [ ] Register with existing email → Should return 409 error
- [ ] Register with existing phone → Should return 409 error
- [ ] Register with invalid data → Should return 400 error
- [ ] Verify country is sent as full name (GHANA, not GH)
- [ ] Verify roles are uppercase (USER, not user)
- [ ] Verify error messages are user-friendly

---

## 📝 Notes

1. **Roles Format**: The API expects roles as a **string** (not array), in **uppercase** format.

2. **Country Format**: The API expects **full country names** (e.g., "GHANA"), not country codes (e.g., "GH").

3. **Phone Number**: Should be sent without country code prefix (e.g., "0244588584" not "+233244588584").

4. **Error Structure**: The API returns errors in a nested structure. The repository now extracts the actual message from `message.message`.

5. **Account Types**: The UI uses lowercase (`user`, `merchant`, `agent`) but these are mapped to uppercase for the API (`USER`, `MERCHANT`, `AGENT`).

