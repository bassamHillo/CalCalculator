# GitHub Setup Instructions

Since you're logged in, please follow these steps:

## Step 1: Add GitHub Secrets

1. **Navigate to Secrets:**
   - Go to: https://github.com/bassamHillo/CalCalculator
   - Click on the **Settings** tab (top of the repository page)
   - In the left sidebar, click **Secrets and variables** > **Actions**
   - Click **New repository secret**

2. **Add Secret 1:**
   - Name: `APP_STORE_CONNECT_API_KEY_ID`
   - Value: (You'll get this from App Store Connect - see below)
   - Click **Add secret**

3. **Add Secret 2:**
   - Click **New repository secret** again
   - Name: `APP_STORE_CONNECT_ISSUER_ID`
   - Value: (You'll get this from App Store Connect - see below)
   - Click **Add secret**

4. **Add Secret 3:**
   - Click **New repository secret** again
   - Name: `APP_STORE_CONNECT_KEY`
   - Value: (Base64-encoded .p8 key file - see below)
   - Click **Add secret**

## Step 2: Protect Main Branch

1. **Navigate to Branch Protection:**
   - Still in Settings, click **Branches** in the left sidebar
   - Under "Branch protection rules", click **Add rule**

2. **Configure the Rule:**
   - **Branch name pattern**: Type `main`
   - Enable these checkboxes:
     - ✅ **Require a pull request before merging**
       - Set "Required number of approvals" to `1`
       - ✅ Dismiss stale pull request approvals when new commits are pushed
     - ✅ **Require status checks to pass before merging**
       - ✅ Require branches to be up to date before merging
       - In the search box, type `test` and select: `test / Run Unit Tests`
     - ✅ **Require conversation resolution before merging**
     - ✅ **Include administrators** (at the bottom)
     - ✅ **Do not allow bypassing the above settings**

3. **Save:**
   - Click **Create** button

---

## App Store Connect API Key (Do this first!)

Before adding GitHub secrets, you need to create an API key in App Store Connect:

1. Go to: https://appstoreconnect.apple.com
2. Sign in
3. Click **Users and Access** (top menu)
4. Click **Keys** tab
5. Click **App Store Connect API** section
6. Click **Generate API Key**
7. Enter name: `CI/CD Key`
8. Select **Access**: `App Manager` or `Admin`
9. Click **Generate**
10. **IMPORTANT**: Download the `.p8` file immediately!
11. Note the **Key ID** and **Issuer ID**

12. **Encode the key file:**
    ```bash
    base64 -i AuthKey_XXXXX.p8 | pbcopy
    ```
    (This copies the encoded key to your clipboard)

Then use these values in the GitHub secrets above.

