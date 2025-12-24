# Fastlane Setup for CalCalculator

This directory contains the Fastlane configuration for automated builds and deployments.

## Prerequisites

1. **App Store Connect API Key**: You need to create an API key in App Store Connect:
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Navigate to Users and Access > Keys
   - Create a new key with "App Manager" or "Admin" role
   - Download the `.p8` key file
   - Note the Key ID and Issuer ID

2. **GitHub Secrets**: Add the following secrets to your GitHub repository:
   - `APP_STORE_CONNECT_API_KEY_ID`: Your API Key ID
   - `APP_STORE_CONNECT_ISSUER_ID`: Your Issuer ID
   - `APP_STORE_CONNECT_KEY`: Base64-encoded content of your `.p8` key file
   - `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`: (Optional) For two-factor authentication

## Local Setup

1. Install Fastlane:
   ```bash
   sudo gem install fastlane
   ```

2. Place your App Store Connect API key in `fastlane/AuthKey.p8`

3. Set environment variables (or add to your shell profile):
   ```bash
   export APP_STORE_CONNECT_API_KEY_ID="YOUR_KEY_ID"
   export APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"
   export APP_STORE_CONNECT_KEY_FILEPATH="./fastlane/AuthKey.p8"
   ```

## Available Lanes

### Test Only
```bash
bundle exec fastlane test
```
Runs unit tests only.

### Deploy to TestFlight
```bash
bundle exec fastlane deploy_to_testflight
```
Runs tests, increments build number, builds the app, and uploads to TestFlight.

## CI/CD

The GitHub Actions workflow (`.github/workflows/ci-cd.yml`) automatically:
1. Runs unit tests on every push to `main` and PRs
2. Deploys to TestFlight only on successful pushes to `main` (after tests pass)

## Notes

- Build numbers are automatically incremented on each deployment
- Release notes are generated from git commit messages since the last tag
- The workflow requires all tests to pass before deployment

