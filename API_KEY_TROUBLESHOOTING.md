# API Key Troubleshooting

## Current Status
The API key authentication is failing with: **"Authentication credentials are missing or invalid"**

## Current Configuration
- **Key ID**: `9D2A5A93W3`
- **Issuer ID**: `19020611-ed38-4968-8ca9-4592b8171acc`
- **Key File**: `fastlane/AuthKey.p8`

## Verification Steps

1. **Check App Store Connect**:
   - Go to https://appstoreconnect.apple.com/access/api
   - Verify Key ID `9D2A5A93W3` exists
   - Check it has **"App Manager"** or **"Admin"** role
   - Ensure it's **Active** (not revoked)

2. **Verify Key ID matches .p8 file**:
   - The Key ID should match the one shown in App Store Connect
   - Download the .p8 file again if needed
   - Make sure you're using the correct .p8 file for Key ID `9D2A5A93W3`

3. **Check Permissions**:
   - The API key needs permission to upload builds to TestFlight
   - Role should be at least "App Manager"

## Alternative: Manual Upload via Xcode

If API key continues to fail, you can upload manually:

1. Open Xcode
2. Go to **Window → Organizer** (Cmd+Shift+2)
3. Find your archive: **playground 2025-12-22 20.46.47**
4. Click **"Distribute App"**
5. Select **"TestFlight & App Store"**
6. Follow the prompts

## Next Steps

Once you verify the API key in App Store Connect:
- Re-run: `fastlane _upload_build` with the correct credentials
- Or use manual upload via Xcode Organizer


