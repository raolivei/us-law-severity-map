# GitHub Actions - Package Push Permissions Fix

## Issue

GitHub Actions workflows fail to push Docker images to GitHub Container Registry (ghcr.io) with a `403 Forbidden` error:

```
ERROR: failed to push ghcr.io/raolivei/us-law-severity-map-web:pr-9:
unexpected status from HEAD request to https://ghcr.io/v2/raolivei/us-law-severity-map-web/blobs/sha256:...: 403 Forbidden
```

## Root Cause

Repository-level workflow permissions are set to **read-only** for packages, which overrides the workflow-level `packages: write` permission declaration.

GitHub uses a two-level permission system:

1. **Repository level** - Sets the maximum permissions (acts as a ceiling)
2. **Workflow level** - Requests specific permissions (cannot exceed repository maximum)

Even though the workflow correctly declares:

```yaml
permissions:
  contents: read
  packages: write
```

The repository-level setting restricts workflows to read-only access, preventing the push operation.

## Solution

### Step 1: Update Repository Settings

1. Navigate to: https://github.com/raolivei/us-law-severity-map/settings/actions
2. Scroll to the **"Workflow permissions"** section
3. Change from:

   - ❌ **"Read repository contents and packages permissions"** (read-only)

   To:

   - ✅ **"Read and write permissions"**

4. Click **"Save"**

### Step 2: Re-run Failed Workflow

After updating the repository settings:

1. Go to the failed workflow run
2. Click **"Re-run jobs"** → **"Re-run all jobs"**
3. The workflow should now successfully push the Docker image

## Verification

A successful workflow run will show:

```
✅ Log in to GitHub Container Registry
✅ Build and push Docker image
✅ Image pushed with digest sha256:...
```

The Docker image will be available at:

```
ghcr.io/raolivei/us-law-severity-map-web:<tag>
```

## Why This Happens

- **Default Security**: GitHub sets repository permissions to read-only by default for security
- **Intentional Design**: Prevents workflows from accidentally pushing to packages without explicit permission
- **Repository Override**: Repository-level settings always take precedence over workflow-level declarations

## Related Files

- `.github/workflows/build-and-push-image.yml` - Main build workflow
- `.github/workflows/build-and-push.yml` - Alternative build workflow with manual dispatch

Both workflows are correctly configured with `packages: write` permission.

## Additional Issue: Package-Level Permissions

If you've already updated repository workflow permissions but still getting 403 errors, the issue is likely at the **package level**.

### Check Package Existence and Permissions

1. Go to: https://github.com/raolivei?tab=packages
2. Look for the package `us-law-severity-map-web`

**If package doesn't exist:**

- The workflow will try to create it on first push
- But package creation may be blocked by repository linking

**If package exists:**

- Package has its own separate permissions
- Repository may not have write access to the package

### Fix Package Permissions

1. Go to the package settings: https://github.com/users/raolivei/packages/container/us-law-severity-map-web/settings
2. Scroll to **"Manage Actions access"**
3. Add repository `raolivei/us-law-severity-map` with **"Write"** access
4. Scroll to **"Danger Zone"** → **"Change package visibility"**
5. Ensure it's set to match your needs (public or private)

### Alternative: Link Repository to Package

If the package exists but isn't linked to the repository:

1. Go to package settings
2. Under **"Manage Actions access"**
3. Click **"Add Repository"**
4. Select `raolivei/us-law-severity-map`
5. Grant **"Write"** permission
6. Save changes

### Verify Push is Enabled

Check your workflow is actually trying to push. Line 58 of `build-and-push-image.yml`:

```yaml
push: ${{ github.event_name != 'pull_request' }}
```

This means:

- ✅ Push on direct commits to main/dev
- ❌ Don't push on pull requests (only builds)

If you want to push on PRs too, change to:

```yaml
push: true
```

## Status

- **Issue Identified**: ✅ November 15, 2024
- **Fix 1 Required**: Repository workflow permissions (✅ DONE)
- **Fix 2 Required**: Package-level permissions (⏳ IN PROGRESS)
- **Impact**: Prevents Docker image publishing to ghcr.io
- **Severity**: High (blocks CI/CD pipeline)

## Additional Notes

- This is a **GitHub UI configuration issue**, not a code issue
- No changes to workflow files are needed
- The fix is permanent - only needs to be done once per repository
- Other workflows may benefit from this permission update

---

**Last Updated**: November 15, 2024  
**Status**: Pending Fix ⏳
