# Docker Image Build and Push Guide

This guide explains how to build and push Docker images for the US Law Severity Map web application to GitHub Container Registry (GHCR).

## Automated Build (GitHub Actions)

The project includes a GitHub Actions workflow that automatically builds and pushes Docker images to GHCR.

### Triggers

The workflow runs automatically on:
- **Push to main branch** - Builds and pushes with `latest` tag
- **Git tags** (e.g., `v1.0.0`) - Builds and pushes with semantic version tags
- **Pull requests** - Builds only (does not push) for testing
- **Manual dispatch** - Allows you to manually trigger with a specific version

### Image Tags

Images are tagged with:
- `latest` - Latest build from main branch
- `v1.0.0` - Specific version tags
- `1.0` - Major.minor version
- `1` - Major version only
- Branch names - For feature branches

### Image Location

Images are pushed to:
```
ghcr.io/raolivei/us-law-severity-map-web:<tag>
```

### Manual Workflow Dispatch

To manually trigger a build with a specific version:

1. Go to **Actions** tab in GitHub
2. Select **Build and Push Docker Image** workflow
3. Click **Run workflow**
4. Enter the version tag (e.g., `v1.0.0`)
5. Click **Run workflow**

## Manual Build (Local)

For local development and testing, use the provided script:

### Prerequisites

1. Docker installed and running
2. GitHub Personal Access Token (PAT) with `write:packages` permission
3. Logged in to GHCR

### Setup

1. **Create a GitHub Personal Access Token:**
   - Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Generate a new token with `write:packages` permission
   - Copy the token

2. **Log in to GHCR:**
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
   ```
   Replace `YOUR_USERNAME` with your GitHub username and set `GITHUB_TOKEN` environment variable.

### Build and Push

**Option 1: Build only**
```bash
./scripts/build-and-push.sh v1.0.0
```

**Option 2: Build and push**
```bash
PUSH=true ./scripts/build-and-push.sh v1.0.0
```

**Option 3: Manual Docker commands**
```bash
# Build
docker build -t ghcr.io/raolivei/us-law-severity-map-web:v1.0.0 .

# Push
docker push ghcr.io/raolivei/us-law-severity-map-web:v1.0.0
docker push ghcr.io/raolivei/us-law-severity-map-web:latest
```

## Kubernetes Deployment

The Kubernetes deployment expects the image at:
```yaml
image: ghcr.io/raolivei/us-law-severity-map-web:v1.0.0
```

### Updating the Deployment

After pushing a new image, update the deployment:

```bash
kubectl set image deployment/us-law-severity-map-web \
  web=ghcr.io/raolivei/us-law-severity-map-web:v1.0.0 \
  -n us-law-severity-map
```

Or edit the deployment file and apply:
```bash
# Edit k8s/deploy.yaml to update the image tag
kubectl apply -f k8s/deploy.yaml
```

## Troubleshooting

### ImagePullBackOff Error

If you see `ImagePullBackOff` in Kubernetes:

1. **Verify the image exists:**
   ```bash
   docker pull ghcr.io/raolivei/us-law-severity-map-web:v1.0.0
   ```

2. **Check image visibility:**
   - Go to https://github.com/raolivei/us-law-severity-map/pkgs/container/us-law-severity-map-web
   - Ensure the package is set to public or your Kubernetes cluster has access

3. **Configure image pull secrets (if private):**
   ```bash
   # Create secret from GitHub token
   kubectl create secret docker-registry ghcr-secret \
     --docker-server=ghcr.io \
     --docker-username=YOUR_USERNAME \
     --docker-password=YOUR_TOKEN \
     --docker-email=YOUR_EMAIL \
     -n us-law-severity-map
   
   # Add to deployment
   kubectl patch deployment us-law-severity-map-web \
     -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ghcr-secret"}]}}}}' \
     -n us-law-severity-map
   ```

### Build Failures

- Check Dockerfile syntax
- Verify all dependencies are available
- Check GitHub Actions logs for detailed error messages
- Ensure the workflow has proper permissions

### Authentication Issues

- Verify your GitHub token has `write:packages` permission
- Check that you're logged in: `docker login ghcr.io`
- For GitHub Actions, ensure `GITHUB_TOKEN` secret is available (automatically provided)

## Best Practices

1. **Version Tagging:** Always use semantic versioning (e.g., `v1.0.0`)
2. **Tag Latest:** Keep `latest` tag updated for convenience
3. **Test Before Push:** Use PR builds to test before merging
4. **Security:** Keep images private unless public access is required
5. **Cleanup:** Periodically remove old image versions to save space

