# Google Play Store Assets Guide

## Required Assets for Play Store Publishing

### 1. App Icon (Already Generated)
- ✅ Generated adaptive launcher icons
- Location: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Sizes: 48x48 to 192x192 dp

### 2. Feature Graphic (1024x500 pixels)
- Required for store listing
- Create a 1024x500 PNG image
- Save as: `assets/images/feature_graphic.png`
- Should showcase your app's main features

### 3. Screenshots (Required)
- **Phone screenshots**: 
  - At least 2 screenshots
  - Recommended: 8-10 screenshots
  - Sizes: 320-3840px, aspect ratio 16:9 or 9:16
  - Save in: `assets/images/screenshots/phone/`

- **Tablet screenshots** (Optional but recommended):
  - Same requirements as phone
  - Save in: `assets/images/screenshots/tablet/`

### 4. App Icon for Store Listing (512x512 pixels)
- High resolution PNG
- Save as: `assets/images/store_icon.png`
- No transparency, clean background

### 5. Promotional Graphics (Optional)
- **Promo image**: 180x120 px
- **TV banner**: 1280x720 px (for Android TV)

## Steps to Prepare Screenshots:

1. **Take screenshots on different screens**:
   - Dashboard/Home
   - Airtime purchase flow
   - Data purchase flow
   - Transaction history
   - Receipt screen
   - Settings/Profile

2. **Edit screenshots** (optional but recommended):
   - Add device frame using tools like:
     - [Screenshot Maker](https://play.google.com/store/apps/details?id=com.screenshot_maker)
     - [MockUPhone](https://mockuphone.com/)
     - [Figma](https://www.figma.com/) with device frames

3. **Organize screenshots**:
   ```
   assets/images/screenshots/
   ├── phone/
   │   ├── 1_dashboard.png
   │   ├── 2_airtime.png
   │   ├── 3_data.png
   │   ├── 4_payment.png
   │   └── 5_receipt.png
   └── tablet/
       ├── 1_dashboard.png
       ├── 2_airtime.png
       └── ...
   ```

## Play Store Listing Information Needed:

### App Details:
- **App name**: LidaPay
- **Short description** (80 characters max)
- **Full description** (4000 characters max)
- **Category**: Finance
- **Content rating**: Everyone
- **Tags**: airtime, data, mobile, recharge, Ghana, remittance

### Privacy Policy URL:
- Host your privacy policy at: `https://your-domain.com/privacy`

### Target Audience:
- Countries: Ghana (primary), other countries as needed
- Age groups: All ages
- Interests: Mobile services, finance, technology

## Release Checklist:

1. ✅ App icon generated
2. ⏳ Create feature graphic (1024x500)
3. ⏳ Take screenshots (minimum 2, recommended 8)
4. ⏳ Create store icon (512x512)
5. ⏳ Write app descriptions
6. ⏳ Set up signing key for release builds
7. ⏳ Test release build
8. ⏳ Upload to Play Console

## Next Steps:

1. Create the feature graphic using your LidaPay logo
2. Take screenshots of key app screens
3. Write compelling app descriptions
4. Generate a signing key for release builds

## Signing Key Generation (When Ready):

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then add to `android/key.properties`:
```
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path to upload-keystore.jks>
```
