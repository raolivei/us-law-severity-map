# Terraform GitHub Actions Workflows

## Overview

This project uses GitHub Actions to provide Atlantis-like functionality for Terraform infrastructure management - completely FREE!

## 🎯 Features

- ✅ **Terraform Plan Preview** on every PR
- ✅ **Automatic Apply** on merge to main
- ✅ **Manual Destroy** workflow with confirmation
- ✅ **PR Comments** with plan details
- ✅ **Format & Validation** checks
- ✅ **Apply Logs** stored as artifacts
- ✅ **Zero Cost** (within GitHub free tier)

---

## 📋 Workflows

### 1. `terraform-plan.yml` - Plan on Pull Request

**Triggers**: When PR is opened/updated and touches Terraform files

**What it does**:
1. ✅ Checks Terraform formatting
2. ✅ Initializes Terraform
3. ✅ Validates configuration
4. ✅ Generates plan
5. ✅ Posts plan as PR comment
6. ✅ Fails if plan has errors

**Example PR Comment**:
```
🏗️ Terraform Plan Results

📋 Terraform Format and Style 🖌 success
⚙️ Terraform Initialization ⚙️ success
🤖 Terraform Validation 🤖 success
📊 Terraform Plan 📊 success

<details>
  <summary>Show Plan</summary>
  
  Terraform will perform the following actions:
  
  # aws_s3_bucket.website will be created
  + resource "aws_s3_bucket" "website" {
      + id = "us-law-severity-map"
      ...
  }
</details>

Pusher: @username
To apply this plan, merge this PR
```

---

### 2. `terraform-apply.yml` - Apply on Merge

**Triggers**: When changes are merged to `main` branch

**What it does**:
1. ✅ Initializes Terraform
2. ✅ Applies changes automatically
3. ✅ Captures outputs (URLs, bucket names, etc.)
4. ✅ Posts results as PR comment
5. ✅ Uploads apply log as artifact

**Example Success Comment**:
```
✅ Terraform Apply Successful

Infrastructure has been updated!

📊 Outputs
- CloudFront Domain: d111111abcdef8.cloudfront.net
- S3 Bucket: us-law-severity-map
- S3 Website: us-law-severity-map.s3-website-us-east-1.amazonaws.com

🌐 Access Your Site
- CloudFront URL: https://d111111abcdef8.cloudfront.net
- S3 Direct: http://us-law-severity-map.s3-website-us-east-1.amazonaws.com

Deployed by: @username
Commit: abc123def456
```

---

### 3. `terraform-destroy.yml` - Manual Destroy

**Triggers**: Manual workflow dispatch only

**What it does**:
1. ⚠️ Requires typing "destroy" to confirm
2. ✅ Destroys all infrastructure
3. ✅ Creates issue documenting destruction
4. ✅ Uploads destroy log

**How to Run**:
1. Go to Actions tab in GitHub
2. Select "Terraform Destroy (Manual)"
3. Click "Run workflow"
4. Type `destroy` in the confirmation field
5. Click "Run workflow" button

---

## 🚀 Setup Instructions

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **GitHub Repository** with these workflows

### Step 1: Configure GitHub Secrets

Go to: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

Add these secrets:

```
AWS_ACCESS_KEY_ID=AKIA***************
AWS_SECRET_ACCESS_KEY=****************************************
```

### Step 2: (Optional) Configure Production Environment

For extra protection on applies:

1. Go to `Settings` → `Environments`
2. Create environment named `production`
3. Add protection rules:
   - ✅ Required reviewers
   - ✅ Wait timer (optional)
   - ✅ Deployment branches (main only)

### Step 3: Test with a PR

```bash
# 1. Create a test branch
git checkout -b test/terraform-workflows

# 2. Make a small change to Terraform
cd terraform/s3-cloudfront
echo "# Test change" >> variables.tf

# 3. Commit and push
git add variables.tf
git commit -m "test: trigger terraform plan workflow"
git push origin test/terraform-workflows

# 4. Create PR on GitHub
# 5. Watch the plan comment appear!
```

---

## 📊 Workflow Comparison

### This Setup vs Atlantis

| Feature | This (GitHub Actions) | Atlantis | Winner |
|---------|----------------------|----------|---------|
| **Cost** | $0/month | $12-50/month | 🏆 GitHub Actions |
| **Setup Time** | 5 minutes | 2-4 hours | 🏆 GitHub Actions |
| **Maintenance** | None | Server updates | 🏆 GitHub Actions |
| **Plan on PR** | ✅ Yes | ✅ Yes | Tie |
| **Apply on Merge** | ✅ Yes | ✅ Yes | Tie |
| **PR Comments** | ✅ Yes | ✅ Yes | Tie |
| **Format Check** | ✅ Yes | ❌ No | 🏆 GitHub Actions |
| **Validation** | ✅ Yes | ❌ No | 🏆 GitHub Actions |
| **Destroy Safety** | ✅ Manual only | ⚠️ Can be automated | 🏆 GitHub Actions |
| **Audit Trail** | ✅ GitHub logs | ✅ Atlantis logs | Tie |

**Verdict**: GitHub Actions wins for small teams! 🎉

---

## 🔒 Security Best Practices

### 1. Use Environment Secrets
```yaml
environment: production  # Requires approval
```

### 2. Limit Permissions
```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write
```

### 3. Branch Protection
- Require PR reviews before merge
- Require status checks to pass
- Require branches to be up to date

### 4. AWS IAM Policy
Minimum required permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "cloudfront:*",
        "acm:*",
        "route53:*"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 📝 Workflow Files

### Location
```
.github/workflows/
├── terraform-plan.yml      # Plan on PR
├── terraform-apply.yml     # Apply on merge
├── terraform-destroy.yml   # Manual destroy
└── deploy-to-s3.yml       # Deploy app (separate)
```

### Triggers Summary

| Workflow | Trigger | Automatic |
|----------|---------|-----------|
| `terraform-plan.yml` | PR with terraform changes | ✅ Yes |
| `terraform-apply.yml` | Push to main (terraform changes) | ✅ Yes |
| `terraform-destroy.yml` | Manual dispatch | ❌ No |
| `deploy-to-s3.yml` | Push to main (app changes) | ✅ Yes |

---

## 🐛 Troubleshooting

### Plan Fails with "Error: No valid credential sources"

**Solution**: Check GitHub Secrets are configured correctly
```bash
# Verify secrets exist (in GitHub UI)
Settings → Secrets → AWS_ACCESS_KEY_ID
Settings → Secrets → AWS_SECRET_ACCESS_KEY
```

### Apply Fails with "Backend not configured"

**Solution**: Ensure Terraform init runs successfully
```yaml
- name: Terraform Init
  run: terraform init
```

### Plan Shows No Changes but Files Were Modified

**Solution**: Check workflow path filters
```yaml
paths:
  - 'terraform/**'  # Must match your structure
```

### Comment Not Appearing on PR

**Solution**: Check workflow permissions
```yaml
permissions:
  pull-requests: write  # Required for comments
```

---

## 💡 Advanced Usage

### Add Auto-Merge After Successful Apply

```yaml
- name: Auto-merge if apply succeeds
  if: success()
  uses: peter-evans/enable-pull-request-automerge@v2
  with:
    pull-request-number: ${{ github.event.number }}
    merge-method: squash
```

### Slack Notifications

```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Terraform apply completed!'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Cost Estimation with Infracost

```yaml
- name: Setup Infracost
  uses: infracost/actions/setup@v2

- name: Generate Cost Estimate
  run: |
    infracost breakdown --path=. \
      --format=json \
      --out-file=/tmp/infracost.json
```

---

## 📈 Monitoring

### View Workflow Runs
```
https://github.com/YOUR_USERNAME/us-law-severity-map/actions
```

### Download Logs
1. Go to Actions tab
2. Click on workflow run
3. Click on job
4. Click "Download log archive" (top right)

### Check Terraform State
```bash
cd terraform/s3-cloudfront
terraform show
```

---

## 🎓 Learning Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Terraform GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [HashiCorp Setup Terraform Action](https://github.com/hashicorp/setup-terraform)

---

## ✅ Checklist

After setting up these workflows:

- [ ] GitHub Secrets configured (AWS credentials)
- [ ] Production environment created (optional)
- [ ] Branch protection rules enabled
- [ ] Test PR created and plan successful
- [ ] First apply completed successfully
- [ ] Outputs visible in PR comment
- [ ] Team members understand workflow

---

**Cost**: $0.00/month  
**Maintenance**: None  
**Value**: Priceless! 🎉

---

## 🆘 Support

Issues with workflows? Check:
1. [GitHub Actions Status](https://www.githubstatus.com/)
2. [Troubleshooting](#-troubleshooting) section above
3. [GitHub Actions Logs](https://github.com/YOUR_USERNAME/us-law-severity-map/actions)

For project-specific help, open an issue on GitHub.

