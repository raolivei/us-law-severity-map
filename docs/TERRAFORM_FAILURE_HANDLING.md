# Terraform Failure Handling

## Overview

This document explains what happens when Terraform operations fail and how the workflows handle these scenarios.

---

## 🔄 Complete Flow

### Success Path (Happy Path)

```
1. Create PR with Terraform changes
   ↓
2. terraform-plan.yml runs
   ✅ Plan succeeds
   ✅ Comment posted to PR
   ↓
3. Review and merge PR
   ↓
4. terraform-apply.yml runs
   ✅ Apply succeeds
   ✅ Success comment posted
   ✅ Infrastructure updated
   ↓
5. Done! 🎉
```

---

### Failure Scenarios

## Scenario 1: Plan Fails ❌

**What Happens:**

```
1. Create PR
   ↓
2. terraform-plan.yml runs
   ❌ Plan fails (syntax error, validation error)
   ❌ PR check marked as failed (red X)
   ↓
3. Cannot merge PR (branch protection)
   ⚠️ Must fix Terraform code first
```

**PR Comment Example:**
```markdown
## 🏗️ Terraform Plan Results

#### 📋 Terraform Format: ✅ success
#### ⚙️ Terraform Init: ✅ success
#### 🤖 Terraform Validate: ❌ failure
#### 📊 Terraform Plan: ❌ failure

<details>
  <summary>Show Plan</summary>
  
  Error: Invalid resource type
  
  on main.tf line 42:
    42: resource "aws_invalid_resource" "test" {
  
  The provider does not support resource type "aws_invalid_resource"
</details>
```

**What You See:**
- ❌ Red X on PR
- ❌ Cannot merge (if branch protection enabled)
- 📝 Error details in PR comment

**What To Do:**
1. Fix the Terraform error
2. Push new commit
3. Plan runs again automatically
4. Repeat until green ✅

---

## Scenario 2: Plan Succeeds ✅ → Apply Fails ❌

**THIS IS THE CRITICAL SCENARIO**

### What Happens NOW (Improved):

```
1. Create PR
   ↓
2. terraform-plan.yml runs
   ✅ Plan succeeds
   ✅ Shows "will create 5 resources"
   ✅ PR comment posted
   ↓
3. Merge PR
   ↓
4. terraform-apply.yml runs
   ❌ Apply fails (AWS quota, permissions, etc.)
   ↓
5. Automatic notifications sent:
   ✅ Comment on merged PR with error
   ✅ New GitHub Issue created
   ✅ Labels added ("terraform-apply-failed", "urgent")
   ✅ Apply log uploaded as artifact
   ✅ Workflow shows red X
```

### PR Comment on Failure:

```markdown
## ❌ Terraform Apply Failed

Infrastructure update failed! Please review the error below.

### 🚨 Error Details

<details><summary>Show Apply Log (last 3000 characters)</summary>

```
Error: Error creating S3 bucket: BucketAlreadyExists: The requested 
bucket name is not available. The bucket namespace is shared by all 
users of the system. Please select a different name and try again.
```

</details>

### 🔍 Common Causes
- AWS quota limits exceeded
- Insufficient IAM permissions
- Resource naming conflicts
- Network/connectivity issues
- State lock conflicts

### 🛠️ Next Steps
1. Check the workflow run for full logs
2. Download the apply.log artifact
3. Fix the issue in the Terraform code
4. Create a new PR with the fix

### 📋 Current State
- **Status**: ⚠️ May be partially applied
- **Action Required**: Review infrastructure state
- **Command**: `cd terraform/s3-cloudfront && terraform state list`

**Failed commit**: abc123def456
**Triggered by**: @your-username
**Workflow**: [View logs](https://github.com/...)
```

### New Issue Created:

```markdown
Title: 🚨 Terraform Apply Failed - Action Required

Labels: bug, terraform, infrastructure, urgent

[Same content as PR comment above]
```

---

## 🔍 Why Does Plan Succeed but Apply Fail?

### Common Reasons:

1. **Timing Issues**
   - Resource available during plan, but taken by someone else during apply
   - Example: S3 bucket name becomes unavailable

2. **Quota Limits**
   - Plan doesn't check AWS service quotas
   - Example: "LimitExceededException: You have reached your limit of CloudFront distributions"

3. **Permissions Changes**
   - IAM permissions changed between plan and apply
   - Example: Someone revoked CloudFront creation permission

4. **State Drift**
   - Someone manually modified infrastructure
   - Terraform state doesn't match reality
   - Example: S3 bucket deleted manually

5. **Network Issues**
   - Temporary AWS API unavailability
   - Timeout issues

6. **Dependency Failures**
   - Plan shows dependency order, but actual creation fails
   - Example: CloudFront creation fails after S3 bucket created

---

## 🛠️ How to Handle Apply Failures

### Step 1: Check Notifications

You'll receive notifications in:
- ✅ GitHub PR comments
- ✅ New GitHub Issue (labeled "urgent")
- ✅ GitHub Actions UI (red X)
- ✅ Email (if configured)

### Step 2: Review Error Details

```bash
# Option 1: Check PR comment (shows last 3000 chars)

# Option 2: Download full log from Actions
1. Go to Actions tab
2. Click failed workflow run
3. Download "terraform-apply-log" artifact
4. Extract and read apply.log

# Option 3: View in workflow output
Click on failed job → Read console output
```

### Step 3: Check Infrastructure State

```bash
cd terraform/s3-cloudfront

# List what was actually created
terraform state list

# See detailed state
terraform show

# Refresh state from AWS
terraform refresh
```

### Step 4: Determine if Partially Applied

```bash
# Check if resources were created
terraform state list

# If empty: nothing was created
# If has items: some resources were created ⚠️
```

### Step 5: Fix the Issue

**Option A: Fix and Retry** (most common)
```bash
# Fix the issue in terraform code
git checkout -b fix/terraform-apply-failure
# ... make changes ...
git commit -m "fix: resolve bucket naming conflict"
git push

# Create new PR
# Plan will run again
# Merge when ready
# Apply will retry
```

**Option B: Manual Cleanup** (if partially applied)
```bash
# Destroy what was created
cd terraform/s3-cloudfront
terraform destroy -target=aws_s3_bucket.website

# Then fix and retry via PR
```

**Option C: Import Existing** (if resource exists)
```bash
# Import manually created resource
terraform import aws_s3_bucket.website bucket-name

# Then update code to match
```

---

## 📋 Troubleshooting Guide

### Error: BucketAlreadyExists

**Cause**: S3 bucket name already taken globally

**Fix**:
```hcl
# terraform/s3-cloudfront/variables.tf
variable "bucket_name" {
  default = "us-law-severity-map-YOUR-UNIQUE-ID"  # ← Add unique suffix
}
```

### Error: LimitExceededException

**Cause**: AWS service quota reached

**Fix**:
```bash
# Check current quotas
aws service-quotas list-service-quotas \
  --service-code cloudfront

# Request quota increase in AWS Console
# Or delete old resources first
```

### Error: UnauthorizedOperation / AccessDenied

**Cause**: Insufficient IAM permissions

**Fix**:
```json
// Add missing permissions to IAM policy
{
  "Effect": "Allow",
  "Action": [
    "s3:CreateBucket",
    "cloudfront:CreateDistribution"
  ],
  "Resource": "*"
}
```

### Error: ResourceInUseException

**Cause**: Resource is being used or modified

**Fix**:
```bash
# Wait a few minutes and retry
# Or check what's using the resource
aws s3api list-bucket-inventories \
  --bucket bucket-name
```

### Error: State Locked

**Cause**: Another operation is running

**Fix**:
```bash
# Wait for other operation to complete
# Or force unlock (dangerous!)
terraform force-unlock LOCK_ID
```

---

## 🔒 Preventing Apply Failures

### 1. Use Unique Resource Names

```hcl
# Add randomness to names
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "website" {
  bucket = "us-law-severity-map-${random_id.suffix.hex}"
}
```

### 2. Check Quotas Before Creating

```bash
# Script to check before applying
aws service-quotas get-service-quota \
  --service-code s3 \
  --quota-code L-DC2B2D3D
```

### 3. Use Terraform Workspaces

```bash
# Separate state per environment
terraform workspace new production
terraform workspace new staging
```

### 4. Enable Resource Timeouts

```hcl
resource "aws_cloudfront_distribution" "website" {
  # ... config ...
  
  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}
```

### 5. Add Depends_On When Needed

```hcl
resource "aws_cloudfront_distribution" "website" {
  # ... config ...
  
  depends_on = [
    aws_s3_bucket.website,
    aws_s3_bucket_policy.website
  ]
}
```

---

## 📊 Workflow Behavior Summary

| Scenario | Plan Status | Apply Status | PR Comment | New Issue | Workflow Status |
|----------|------------|--------------|------------|-----------|-----------------|
| All Success | ✅ Pass | ✅ Pass | ✅ Success | ❌ No | ✅ Green |
| Plan Fails | ❌ Fail | 🚫 Not Run | ✅ Error shown | ❌ No | ❌ Red |
| Apply Fails | ✅ Pass | ❌ Fail | ✅ Error shown | ✅ Yes | ❌ Red |

---

## 🆘 When to Get Help

Contact maintainer or open issue if:

- ❌ Apply fails consistently with same error
- ❌ State is corrupted
- ❌ Infrastructure partially created and can't be destroyed
- ❌ AWS account issues (billing, quotas)
- ❌ Workflow doesn't post failure comments

---

## ✅ Best Practices

1. **Always Review Plan** before merging
2. **Monitor Apply** in Actions tab after merge
3. **Check State** if apply fails
4. **Fix Quickly** when failures occur
5. **Learn** from each failure (update this doc!)

---

## 📚 Related Documentation

- [Terraform Workflows](TERRAFORM_WORKFLOWS.md)
- [AWS Deployment Guide](AWS_DEPLOYMENT.md)
- [Cost Analysis](AWS_COST_ANALYSIS.md)

---

**Last Updated**: October 29, 2025  
**Workflow Version**: v2.0 with failure handling

