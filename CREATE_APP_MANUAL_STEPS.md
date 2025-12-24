# Create App in App Store Connect - Manual Steps

## Why This Is Needed
Before uploading builds to TestFlight, the app must be registered in App Store Connect with bundle ID `CalCalculatorAi`.

## Steps to Create the App

1. **Go to App Store Connect**
   - Visit: https://appstoreconnect.apple.com
   - Sign in with your Apple ID: `zoharb157@gmail.com`

2. **Navigate to My Apps**
   - Click **"My Apps"** in the top navigation
   - Click the **"+"** button (top left)
   - Select **"New App"**

3. **Fill in App Information**
   - **Platform**: iOS
   - **Name**: CalCalculator
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select `CalCalculatorAi` (or create it if it doesn't exist)
   - **SKU**: `CalCalculatorAi` (or any unique identifier)
   - **User Access**: Full Access (or as needed)

4. **Create the App**
   - Click **"Create"**
   - The app will be created in App Store Connect

## After Creating the App

Once the app is created, you can:
- Upload builds via Xcode Organizer (manual)
- Or retry Fastlane upload (if API key is fixed)

## Verify App Exists

To verify the app was created:
1. Go to https://appstoreconnect.apple.com/apps
2. You should see "CalCalculator" in your apps list
3. Click on it to see the app details

## Next Steps

After creating the app:
1. Try the upload again: `fastlane _upload_build`
2. Or use Xcode Organizer for manual upload


