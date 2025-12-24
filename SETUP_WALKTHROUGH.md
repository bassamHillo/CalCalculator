# Step-by-Step Setup Walkthrough

## Part 1: App Store Connect API Key Setup

### Step 1: Log in to App Store Connect
1. Go to https://appstoreconnect.apple.com
2. Sign in with your Apple ID

### Step 2: Navigate to API Keys
1. Once logged in, click on **Users and Access** in the top menu
2. Click on **Keys** tab
3. Click on **App Store Connect API** section

### Step 3: Create API Key
1. Click **Generate API Key** button
2. Enter a name: `CI/CD Key` (or any name you prefer)
3. Select **Access**: Choose **App Manager** or **Admin** role
4. Click **Generate**
5. **IMPORTANT**: Download the `.p8` key file immediately (you can only download it once!)
6. Note down:
   - **Key ID** (starts with something like `S6B4NH8V4A`)
   - **Issuer ID** (UUID format like `f65558d9-dfa4-4b65-aef2-4cf70b2196f4`)

### Step 4: Encode the Key File
Run this command in your terminal:
```bash
base64 -i AuthKey_XXXXX.p8 | pbcopy
```
(Replace `XXXXX` with your actual Key ID)

This copies the base64-encoded key to your clipboard.

---

## Part 2: GitHub Secrets Setup

### Step 1: Log in to GitHub
1. Go to https://github.com/bassamHillo/CalCalculator
2. Sign in if needed

### Step 2: Navigate to Secrets
1. Click on **Settings** tab (top of repository page)
2. In the left sidebar, click **Secrets and variables** > **Actions**
3. Click **New repository secret**

### Step 3: Add Secrets (repeat for each)
Add these three secrets:

**Secret 1:**
- Name: `APP_STORE_CONNECT_API_KEY_ID`
- Value: Your Key ID from App Store Connect (e.g., `S6B4NH8V4A`)

**Secret 2:**
- Name: `APP_STORE_CONNECT_ISSUER_ID`
- Value: Your Issuer ID from App Store Connect (e.g., `f65558d9-dfa4-4b65-aef2-4cf70b2196f4`)

**Secret 3:**
- Name: `APP_STORE_CONNECT_KEY`
- Value: Paste the base64-encoded key from your clipboard (from Step 4 above)

---

## Part 3: Branch Protection Setup

### Step 1: Navigate to Branch Settings
1. In GitHub repository, go to **Settings** > **Branches**
2. Under **Branch protection rules**, click **Add rule**

### Step 2: Configure Protection
1. **Branch name pattern**: Enter `main`
2. Enable these options:
   - ✅ **Require a pull request before merging**
     - ✅ Require approvals: `1`
     - ✅ Dismiss stale pull request approvals when new commits are pushed
   - ✅ **Require status checks to pass before merging**
     - ✅ Require branches to be up to date before merging
     - Select: `test / Run Unit Tests`
   - ✅ **Require conversation resolution before merging**
   - ✅ **Include administrators** (applies rules to admins too)
   - ✅ **Do not allow bypassing the above settings**

3. Click **Create** or **Save changes**

---

## Verification

After completing all steps:

1. **Test the workflow:**
   - Create a test branch
   - Make a small change
   - Create a PR
   - Check the **Actions** tab to see if tests run

2. **Test deployment:**
   - Merge a PR to `main`
   - Check **Actions** tab
   - Verify it builds and uploads to TestFlight

---

## Troubleshooting

- **API Key not working?** Make sure the key has proper permissions (App Manager or Admin)
- **Secrets not found?** Check that secret names match exactly (case-sensitive)
- **Tests failing?** Check the Actions tab logs for specific errors
- **Deployment failing?** Verify all three secrets are set correctly

