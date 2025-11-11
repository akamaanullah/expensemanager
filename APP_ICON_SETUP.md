# App Icon Setup Guide

## Step 1: Create Icon Image
1. Create a square icon image (1024x1024 pixels recommended)
2. Use PNG format
3. Design your icon with wallet/expense theme

## Step 2: Add Icon to Project
1. Create folder: `assets/icon/`
2. Save your icon as: `assets/icon/app_icon.png`

## Step 3: Generate App Icons
Run this command:
```bash
flutter pub run flutter_launcher_icons
```

## Step 4: Rebuild App
After generating icons, rebuild the app:
```bash
flutter clean
flutter run
```

## Alternative: Manual Icon Replacement
If you prefer to manually replace icons:

1. Go to: `android/app/src/main/res/`
2. Replace icons in these folders:
   - `mipmap-mdpi/ic_launcher.png` (48x48)
   - `mipmap-hdpi/ic_launcher.png` (72x72)
   - `mipmap-xhdpi/ic_launcher.png` (96x96)
   - `mipmap-xxhdpi/ic_launcher.png` (144x144)
   - `mipmap-xxxhdpi/ic_launcher.png` (192x192)

## Quick Setup (Using Default Icon)
If you want to use a simple wallet icon for now, you can:
1. Use any online icon generator (like https://www.appicon.co/)
2. Upload your design or use a wallet icon
3. Download the generated icons
4. Replace the icons in `android/app/src/main/res/mipmap-*/` folders



