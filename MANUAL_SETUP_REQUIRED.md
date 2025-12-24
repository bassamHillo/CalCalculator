# Manual Setup Required

## Current Status
✅ CI/CD pipeline code is set up and committed  
✅ Fastlane configuration is ready  
✅ GitHub Actions workflow is configured  
❌ GitHub Secrets need to be added (requires admin access)  
❌ Branch protection needs to be enabled (requires admin access)

## Issue
Your GitHub account (`zoharb157`) doesn't have admin permissions on the `bassamHillo/CalCalculator` repository. You need admin access to:
- Add repository secrets
- Enable branch protection

## Solutions

### Option 1: Get Admin Access (Recommended)
Ask the repository owner (`bassamHillo`) to:
1. Go to repository Settings > Collaborators
2. Find your account (`zoharb157`)
3. Change your role to **Admin**

Then you can complete the setup.

### Option 2: Owner Does the Setup
If you can't get admin access, ask the repository owner to complete these steps:

## Step 1: Add GitHub Secrets

**URL:** https://github.com/bassamHillo/CalCalculator/settings/secrets/actions

1. Click **New repository secret**
2. Add these three secrets:

   **Secret 1:**
   - Name: `APP_STORE_CONNECT_API_KEY_ID`
   - Value: (Get from App Store Connect - see below)

   **Secret 2:**
   - Name: `APP_STORE_CONNECT_ISSUER_ID`
   - Value: (Get from App Store Connect - see below)

   **Secret 3:**
   - Name: `APP_STORE_CONNECT_KEY`
   - Value: (Base64-encoded .p8 file - see below)

## Step 2: Protect Main Branch

**URL:** https://github.com/bassamHillo/CalCalculator/settings/branches

1. Click **Add rule**
2. **Branch name pattern:** `main`
3. Enable:
   - ✅ **Require a pull request before merging**
     - Required approvals: `1`
     - ✅ Dismiss stale reviews
   - ✅ **Require status checks to pass before merging**
     - ✅ Require branches to be up to date
     - Select: `test / Run Unit Tests`
   - ✅ **Require conversation resolution**
   - ✅ **Include administrators**
4. Click **Create**

## Step 3: Get App Store Connect API Key

**URL:** https://appstoreconnect.apple.com/access/api

1. Sign in to App Store Connect
2. Click **Users and Access** > **Keys** > **App Store Connect API**
3. Click **Generate API Key**
4. Name: `CI/CD Key`
5. Access: `App Manager` or `Admin`
6. Click **Generate**
7. **Download the .p8 file immediately!**
8. Note the **Key ID** and **Issuer ID**

9. **Encode the key:**
   ```bash
   base64 -i AuthKey_XXXXX.p8 | pbcopy
   ```
   (This copies the encoded key to clipboard)

10. Use these values in the GitHub secrets above.

## Verification

After setup:
1. Create a test PR
2. Check **Actions** tab - tests should run
3. Merge PR to `main`
4. Check **Actions** tab - should deploy to TestFlight

## Quick Links

- **Secrets:** https://github.com/bassamHillo/CalCalculator/settings/secrets/actions
- **Branch Protection:** https://github.com/bassamHillo/CalCalculator/settings/branches
- **App Store Connect API:** https://appstoreconnect.apple.com/access/api

