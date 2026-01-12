# LidaPay Mobile App

A Flutter mobile application for international and local airtime and internet data remittance, specifically designed for the Ghana market.

## Features

- 🌍 **Global & Local Airtime**: Purchase airtime via Reloadly (Global) and Prymo (Ghana)
- 📱 **Data Bundles**: Buy internet data for local and international carriers
- 💳 **Payment Gateway**: Integrated with ExpressPay Ghana for secure payments
- 💰 **Funds Transfer**: Send money to contacts (coming soon)
- 💵 **Airtime to Cash**: Convert airtime to cash (coming soon)
- 📊 **Statistics**: Track spending with beautiful charts and analytics
- 🎨 **Modern UI**: Beautiful dark/light themes with smooth animations

## Architecture

- **State Management**: Riverpod
- **Navigation**: go_router
- **Networking**: Dio with interceptors
- **Models**: Freezed + JsonSerializable
- **Local Storage**: SharedPreferences + Hydrated Storage

## Backend Integration

The app integrates with the NestJS backend API:
- **API Documentation**: https://api.advansistechnologies.com/api-doc
- **Endpoints**: 
  - Reloadly Global API for international airtime
  - Prymo API for Ghana local airtime
  - ExpressPay Ghana payment gateway

## Setup

1. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

2. **Generate code**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Configure environment**:
   - Copy `.env.example` to `.env`
   - Update API base URL and keys

4. **Run the app**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── domain/
│   ├── entities/
│   └── repositories/
├── presentation/
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── airtime/
│   │   ├── transactions/
│   │   └── settings/
│   └── routes/
└── main.dart
```

## Environment Variables

Create a `.env` file in the root directory:

```env
API_BASE_URL=https://api.advansistechnologies.com
API_KEY=your_api_key_here
```

## Testing

Run tests:
```bash
flutter test
```

Run with coverage:
```bash
flutter test --coverage
```

## Build

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Android run device
```bash
flutter build apk --release
adb install app-release.apk
```

### iOS run device
```bash
flutter build ios --release
```

## License

Proprietary - Advansis Technologies

