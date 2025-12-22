# Branch Protection Setup Guide

This guide explains how to protect the `main` branch in your GitHub repository.

## Steps to Protect the Main Branch

1. **Navigate to Repository Settings**
   - Go to your repository on GitHub
   - Click on "Settings" tab
   - Click on "Branches" in the left sidebar

2. **Add Branch Protection Rule**
   - Click "Add rule" or "Add branch protection rule"
   - In the "Branch name pattern" field, enter: `main`

3. **Configure Protection Settings**
   
   **Required Settings:**
   - ✅ **Require a pull request before merging**
     - ✅ Require approvals: `1` (or more as needed)
     - ✅ Dismiss stale pull request approvals when new commits are pushed
     - ✅ Require review from Code Owners (if you have CODEOWNERS file)
   
   - ✅ **Require status checks to pass before merging**
     - ✅ Require branches to be up to date before merging
     - Select the following status checks:
       - `test / Run Unit Tests`
       - `deploy / Deploy to TestFlight` (optional, can be skipped if you want)
   
   - ✅ **Require conversation resolution before merging**
   
   - ✅ **Do not allow bypassing the above settings** (for administrators)

   **Optional but Recommended:**
   - ✅ **Require linear history** (prevents merge commits)
   - ✅ **Include administrators** (applies rules to admins too)
   - ✅ **Restrict who can push to matching branches** (only allow via PR)

4. **Save the Rule**
   - Click "Create" or "Save changes"

## What This Means

Once protected, the `main` branch will:
- ✅ Only accept changes via Pull Requests
- ✅ Require at least one approval before merging
- ✅ Require all CI/CD tests to pass
- ✅ Prevent force pushes
- ✅ Prevent deletion of the branch

## Testing the Protection

Try to push directly to `main`:
```bash
git checkout main
# Make a change
git commit -m "Test direct push"
git push origin main
```

You should see an error indicating the branch is protected. Instead, create a branch and PR:
```bash
git checkout -b test-branch
# Make changes
git commit -m "Test changes"
git push origin test-branch
# Create PR on GitHub
```

## Additional Security (Optional)

You can also:
- Set up CODEOWNERS file for automatic reviewer assignment
- Require signed commits
- Set up branch protection for other branches (like `develop`, `release/*`)

