# LidaPay Flutter App - Setup Guide

## Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code with Flutter extensions
- Git

## Initial Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Code

The project uses code generation for:
- Freezed models (`*.freezed.dart`)
- JSON serialization (`*.g.dart`)
- Retrofit API client (`api_client.g.dart`)

Run the code generator:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

For continuous generation during development:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 3. Configure Environment

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Update `.env` with your API credentials:
   ```env
   API_BASE_URL=https://api.advansistechnologies.com
   API_KEY=your_api_key_here
   ```

### 4. API Integration

The app integrates with your NestJS backend at `https://api.advansistechnologies.com/api-doc`:

- **Reloadly Global API**: For international airtime purchases
- **Prymo API**: For Ghana local airtime purchases  
- **ExpressPay Ghana**: Payment gateway integration

All endpoints are configured in `lib/data/datasources/api_client.dart`.

## Project Structure

```
lib/
├── core/                    # Core utilities and configurations
│   ├── constants/           # App constants
│   ├── routes/              # Navigation configuration
│   ├── theme/               # Theme and styling
│   └── utils/               # Utility functions
├── data/                    # Data layer
│   ├── datasources/         # API clients and data sources
│   ├── models/              # Data models (Freezed)
│   └── repositories/        # Repository implementations
├── presentation/            # UI layer
│   ├── features/            # Feature modules
│   │   ├── auth/           # Authentication screens
│   │   ├── dashboard/      # Dashboard screen
│   │   ├── airtime/        # Airtime purchase flow
│   │   ├── transactions/   # Transaction history
│   │   └── settings/       # Settings and profile
│   └── providers/          # Riverpod state providers
└── main.dart               # App entry point
```

## Running the App

### Development

```bash
flutter run
```

### Build for Release

**Android:**
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## Key Features Implemented

### ✅ Authentication
- Phone/email + password login
- OTP verification flow
- Persistent session management
- Token refresh mechanism

### ✅ Dashboard
- Wallet balance display
- Quick action buttons (Send, Receive, Family, More)
- Recent transactions list
- Promotional cards

### ✅ Airtime Purchase Flow
1. Select recipient (from contacts or manual entry)
2. Enter amount with currency conversion
3. Confirm transaction with payment method selection
4. Integration with Reloadly (Global) and Prymo (Ghana)

### ✅ Transactions
- Transaction history with filters
- Transaction details
- Status indicators

### ✅ Statistics
- Expense/Income charts
- Monthly statistics
- History view

### ✅ Settings & Profile
- User profile management
- KYC verification status
- Payment methods
- Theme preferences

## State Management

The app uses **Riverpod** for state management:

- `authStateProvider`: Authentication state
- `balanceProvider`: Wallet balance
- `airtimePurchaseProvider`: Airtime purchase state
- `transactionsProvider`: Transaction list
- `statisticsProvider`: Statistics data

## Theming

The app supports both light and dark themes:

- **Light Theme**: Blue accents (`AppColors.lightPrimary`)
- **Dark Theme**: Green accents (`AppColors.darkPrimary`)

Theme can be toggled in Settings screen.

## API Endpoints Used

Based on your NestJS backend at `https://api.advansistechnologies.com/api-doc`:

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/verify-otp` - OTP verification
- `POST /api/auth/refresh` - Token refresh

### Wallet
- `GET /api/wallet/balance` - Get wallet balance

### Airtime
- `POST /api/airtime/reloadly` - Purchase via Reloadly (Global)
- `POST /api/airtime/prymo` - Purchase via Prymo (Ghana)

### Data
- `POST /api/data/purchase` - Purchase data bundles

### Transactions
- `GET /api/transactions` - Get transaction list
- `GET /api/transactions/{id}` - Get transaction details

### Statistics
- `GET /api/statistics` - Get statistics data

## Testing

Run tests:
```bash
flutter test
```

Run with coverage:
```bash
flutter test --coverage
```

## Troubleshooting

### Flutter Doctor Issues

#### Android Toolchain - Missing cmdline-tools

If `flutter doctor` shows "cmdline-tools component is missing":

**Option 1: Install via Android Studio (Recommended)**
1. Open Android Studio
2. Go to **Tools** → **SDK Manager**
3. Click on the **SDK Tools** tab
4. Check **Android SDK Command-line Tools (latest)**
5. Click **Apply** to install

**Option 2: Manual Installation**
1. Download command-line tools from: https://developer.android.com/studio#command-line-tools-only
2. Extract to: `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\`
3. Set environment variable `ANDROID_HOME` to `%LOCALAPPDATA%\Android\Sdk`
4. Add to PATH: `%ANDROID_HOME%\cmdline-tools\latest\bin` and `%ANDROID_HOME%\platform-tools`

**Verify Installation:**
```bash
flutter doctor --android-licenses
```

#### Android Licenses Not Accepted

After installing cmdline-tools, accept Android licenses:

```bash
flutter doctor --android-licenses
```

Press `y` to accept each license agreement.

#### Visual Studio Not Installed (Windows App Development)

If you need to develop Windows apps, install Visual Studio:

1. Download Visual Studio from: https://visualstudio.microsoft.com/downloads/
2. During installation, select the **"Desktop development with C++"** workload
3. Ensure all default components are included
4. Restart your terminal and run `flutter doctor` again

**Note:** Visual Studio is only required if you plan to build Windows desktop apps. For Android/web development, you can skip this.

### Code Generation Issues

If you encounter issues with generated files:

```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### API Connection Issues

1. Verify your `.env` file has correct `API_BASE_URL`
2. Check network connectivity
3. Verify API endpoints match your backend documentation
4. Check authentication token is being sent correctly

### Build Issues

1. Ensure Flutter SDK is up to date: `flutter upgrade`
2. Clean build: `flutter clean`
3. Get dependencies: `flutter pub get`
4. Regenerate code: `flutter pub run build_runner build --delete-conflicting-outputs`

## Next Steps

### Planned Features (Placeholders Ready)

1. **Funds Transfer**: UI flow ready, needs backend integration
2. **Airtime to Cash**: UI flow ready, needs backend integration
3. **Bill Payments**: UI structure ready
4. **KYC Verification**: Status display ready, needs full flow

### Customization

- **Colors**: Edit `lib/core/theme/app_theme.dart`
- **API Endpoints**: Edit `lib/data/datasources/api_client.dart`
- **Constants**: Edit `lib/core/constants/app_constants.dart`
- **Routes**: Edit `lib/core/routes/app_router.dart`

## Support

For API documentation, visit: https://api.advansistechnologies.com/api-doc

## License

Proprietary - Advansis Technologies

