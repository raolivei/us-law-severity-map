# Delete and Recreate GHCR Package

This is the **nuclear option** to fix the persistent 403 Forbidden error with the GitHub Container Registry package.

## Why This Might Be Necessary

Even after:

- ✅ Fixing repository workflow permissions
- ✅ Linking the package to the repository
- ✅ Re-running the workflow multiple times

The package still has permission issues. This suggests the package was created with incorrect permissions that can't be easily fixed.

## Steps to Fix

### 1. Delete the Existing Package

**Via GitHub UI:**

1. Go to: https://github.com/users/raolivei/packages/container/us-law-severity-map-web
2. Click **"Package settings"** (right sidebar)
3. Scroll all the way down to **"Danger Zone"**
4. Click **"Delete this package"**
5. Type the package name to confirm: `us-law-severity-map-web`
6. Click **"I understand, delete this package"**

**Via GitHub CLI (if you have `gh` installed):**

```bash
# List packages to confirm the name
gh api user/packages/container

# Delete the package
gh api \
  --method DELETE \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /user/packages/container/us-law-severity-map-web
```

### 2. Push Directly to Main Branch (Not a PR)

The workflow is configured to only push on direct commits to `main` or `dev` branches, NOT on pull requests.

**Option A: Merge your PR first, then let the workflow run on main**

```bash
cd /Users/roliveira/WORKSPACE/raolivei/us-law-severity-map

# Make sure you're on your feature branch
git status

# Push any final changes
git push origin <your-branch-name>

# Then merge the PR on GitHub UI
```

After merging, the workflow will run on the `main` branch and will attempt to push the image (since it's not a PR anymore).

**Option B: Push directly to dev branch**

```bash
cd /Users/roliveira/WORKSPACE/raolivei/us-law-severity-map

# Switch to dev branch
git checkout dev
git pull origin dev

# Merge your changes
git merge <your-feature-branch>

# Push to dev
git push origin dev
```

This will trigger the workflow on `dev` branch (not a PR), so it will push the image.

**Option C: Use workflow_dispatch to manually trigger**

```bash
# Using GitHub CLI
gh workflow run build-and-push.yml \
  --ref main \
  --field tag=test
```

Or via GitHub UI:

1. Go to: Actions → "Build and Push Docker Image"
2. Click "Run workflow"
3. Select branch: `main` or `dev`
4. Enter a tag (optional): `test`
5. Click "Run workflow"

### 3. Verify Package Creation

After the workflow runs successfully:

1. Go to: https://github.com/raolivei?tab=packages
2. Check that `us-law-severity-map-web` exists
3. Click on it
4. Verify it's linked to `us-law-severity-map` repository
5. Check that it shows "Write" access for the repository

### 4. Re-run Your PR Workflow (Optional)

Once the package exists with correct permissions, your PR workflows should work (though they won't push, just build).

## Why PRs Don't Push Images

Your workflow configuration (line 58/65 in both workflow files):

```yaml
push: ${{ github.event_name != 'pull_request' }}
```

This means:

- ✅ **Push to registry**: When commits are pushed to `main` or `dev`
- ❌ **Don't push to registry**: When running on pull requests (just build to verify)

This is intentional and a best practice - you don't want every PR creating new tagged images.

## If You Want PRs to Push

If you actually want PRs to push images, change the workflow:

```yaml
# OLD:
push: ${{ github.event_name != 'pull_request' }}

# NEW:
push: true
```

But this is generally not recommended unless you have a specific need for PR-tagged images.

---

**Last Updated**: November 15, 2024  
**Status**: Ready to execute
