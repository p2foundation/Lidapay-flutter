# Android Signing Configuration

## IMPORTANT: Generate Your Release Signing Key

Before publishing to Play Store, you need to generate a signing key. Follow these steps:

### 1. Generate Keystore

Open terminal/command prompt and run:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important:**
- Store this file securely! If you lose it, you cannot update your app.
- Use a strong password
- Keep backup copies in secure locations
- Don't commit this file to version control

### 2. Create key.properties file

Create a file `android/key.properties` with:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-upload-keystore.jks>
```

Example:
```properties
storePassword=myStrongPassword123
keyPassword=myKeyPassword456
keyAlias=upload
storeFile=../upload-keystore.jks
```

### 3. Add key.properties to .gitignore

Add this line to your `.gitignore` file:
```
android/key.properties
*.jks
```

### 4. Update build.gradle.kts

The build.gradle.kts file is already configured to read from key.properties when it exists.

## Testing Release Build

After setting up signing key:

```bash
# Clean build
flutter clean
flutter pub get

# Build release APK (for testing)
flutter build apk --release

# Build release AAB (for Play Store)
flutter build appbundle --release
```

## Play Store Upload Process

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app or select existing
3. Fill in store listing information (see STORE_CONTENT.md)
4. Upload app bundle (.aab) file
5. Complete content rating questionnaire
6. Set pricing and distribution
7. Review and roll out

## ProGuard

ProGuard is configured to:
- Shrink and obfuscate code
- Keep necessary API models and Retrofit classes
- Protect Flutter engine classes

## Version Management

Current version: 1.0.1 (versionCode: 2)

To update:
1. Increment versionCode in build.gradle.kts
2. Update versionName
3. Update version in pubspec.yaml
4. Add release notes to STORE_CONTENT.md

## Security Best Practices

1. **Never** commit signing keys to version control
2. Use different passwords for keystore and key
3. Store passwords securely (password manager)
4. Have backup procedures for signing keys
5. Use Google App Signing for additional security

## Troubleshooting

### "INSTALL_PARSE_FAILED_NO_CERTIFICATES"
- Ensure you're using the same signing key for updates
- Check if key.properties is correctly configured

### "Signing configuration is not configured"
- Verify key.properties exists
- Check file paths in key.properties
- Ensure passwords are correct

### "APK is not zip aligned"
- This is handled automatically by Flutter build tools
- If issues persist, run `flutter clean` and rebuild
