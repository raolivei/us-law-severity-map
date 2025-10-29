# Test Terraform Apply Before Merge

## 🎯 Overview

This workflow allows you to **test `terraform apply` BEFORE merging** your PR. This is much safer than merging first and hoping it works!

---

## 🔄 How It Works

### Traditional Flow (Risky)

```
1. Create PR
2. Plan runs (shows what will happen)
3. Merge PR ← 🚨 Point of no return!
4. Apply runs
5. Hope it works... ❌ If it fails, PR already merged!
```

### New Flow (Safe)

```
1. Create PR
2. Plan runs (shows what will happen)
3. Add "test-apply" label ← 🧪 Test it first!
4. Apply runs on PR
5. See if it works ← ✅ If it fails, PR NOT merged yet!
6. Merge PR manually (only if apply succeeded)
```

---

## 📋 Step-by-Step Guide

### Step 1: Create PR with Terraform Changes

```bash
git checkout -b feat/update-infrastructure
cd terraform/s3-cloudfront

# Make your changes
vi main.tf

git add .
git commit -m "feat: add tags to S3 bucket"
git push origin feat/update-infrastructure
```

Create PR on GitHub.

---

### Step 2: Review the Plan

The workflow will automatically:

- ✅ Run `terraform plan`
- ✅ Post results as PR comment

**PR Comment Example:**

```markdown
## 🏗️ Terraform Plan Results

#### 📋 Format: ✅ success

#### ⚙️ Init: ✅ success

#### 🤖 Validate: ✅ success

#### 📊 Plan: ✅ success

<details>
  <summary>Show Plan</summary>
  
  Plan: 1 to change, 0 to add, 0 to destroy.
  
  ~ aws_s3_bucket.website
    tags = {
      + "Environment" = "production"
    }
</details>

---

### 🎯 Next Steps

**To test this infrastructure before merging:**

Add the label `test-apply` to this PR to run `terraform apply`.

This will:

- ✅ Actually create the infrastructure
- ✅ Show you if it works in production
- ✅ Post results here
- ⚠️ You can then decide to merge or rollback
```

---

### Step 3: Add "test-apply" Label

**In GitHub PR:**

1. Click "Labels" on the right sidebar
2. Add label: `test-apply`

![Add Label](https://user-images.githubusercontent.com/...label.png)

**This triggers the apply workflow!**

---

### Step 4: Watch the Apply Run

Go to "Actions" tab and watch:

- `Terraform Apply (Test)` job running
- Real infrastructure being created
- Live logs

**Timeline:**

```
⏱️ Plan job: ~1 minute
⏱️ Apply job: ~5-15 minutes (depending on resources)
```

---

### Step 5A: If Apply Succeeds ✅

**New PR Comment:**

```markdown
## ✅ Test Apply Successful!

Infrastructure was successfully created/updated!

### 📊 Outputs

- **CloudFront Domain**: `d123abc.cloudfront.net`
- **S3 Bucket**: `us-law-severity-map`
- **S3 Website**: `us-law-severity-map.s3-website-us-east-1.amazonaws.com`

### 🌐 Test Your Site

- CloudFront: https://d123abc.cloudfront.net
- S3 Direct: http://us-law-severity-map.s3-website-us-east-1.amazonaws.com

### ✅ Ready to Merge

The infrastructure is working! You can now:

1. **Test the deployed infrastructure** using the URLs above
2. **Merge this PR** when you're satisfied
3. The infrastructure will remain as-is after merge

**Note**: Since apply already succeeded, merging won't change anything.
The infrastructure is already live! 🎉
```

**Labels Added:**

- ✅ `terraform-apply-success`
- ✅ `ready-to-merge`

**What to do:**

1. ✅ Test the URLs provided
2. ✅ Verify everything works
3. ✅ Click "Merge pull request"
4. ✅ Done! Infrastructure is live and PR is merged

---

### Step 5B: If Apply Fails ❌

**New PR Comment:**

```markdown
## ❌ Test Apply Failed

The infrastructure could not be created. **DO NOT MERGE** until this is fixed.

### 🚨 Error Details

<details>
  <summary>Show Apply Log</summary>
  
  Error: Error creating S3 bucket: BucketAlreadyExists
  The requested bucket name is not available.
</details>

### 🛠️ Next Steps

1. **Review the error above**
2. **Fix the Terraform code**
3. **Push new commit** (this will re-run plan)
4. **Add `test-apply` label again** to test

### ⚠️ Important

DO NOT merge this PR until apply succeeds!
```

**Labels Added:**

- ❌ `terraform-apply-failed`
- ⚠️ `do-not-merge`

**What to do:**

1. ❌ **DO NOT MERGE!**
2. 🔧 Fix the error in your code
3. 📝 Push new commit
4. 🔄 Remove `test-apply` label
5. 🎯 Add `test-apply` label again
6. ⏱️ Wait for new apply
7. ✅ Repeat until success

---

## 🎭 Example Scenarios

### Scenario 1: Everything Works First Try

```bash
# 1. Create PR
git checkout -b feat/add-cloudfront-geo-restriction
# ... make changes ...
git push

# 2. Wait for plan ✅

# 3. Add "test-apply" label

# 4. Wait 10 minutes ✅

# 5. Comment appears: "✅ Test Apply Successful!"

# 6. Test the URLs - works great!

# 7. Click "Merge"

# Done! 🎉
```

**Time**: ~15 minutes  
**Risk**: Zero (tested before merge)  
**Result**: Success!

---

### Scenario 2: Apply Fails, You Fix It

```bash
# 1. Create PR with bucket name conflict
git push

# 2. Plan shows ✅ (looks fine)

# 3. Add "test-apply" label

# 4. Apply fails ❌ (BucketAlreadyExists)

# 5. PR comment shows error

# 6. Fix the bucket name
vi terraform/s3-cloudfront/variables.tf
# Change: bucket_name = "us-law-severity-map-unique-123"
git commit -m "fix: use unique bucket name"
git push

# 7. Remove "test-apply" label

# 8. Plan runs again ✅

# 9. Add "test-apply" label again

# 10. Apply succeeds ✅

# 11. Test URLs - works!

# 12. Merge PR

# Done! 🎉
```

**Time**: ~30 minutes (with one retry)  
**Risk**: Zero (never merged broken code)  
**Result**: Success!

---

## ⚡ Quick Commands

### Test Apply on PR

```bash
# Using GitHub CLI
gh pr edit PR_NUMBER --add-label "test-apply"
```

### Remove Label to Retry

```bash
gh pr edit PR_NUMBER --remove-label "test-apply"
gh pr edit PR_NUMBER --add-label "test-apply"
```

### Check Apply Status

```bash
gh run list --workflow="Terraform Plan and Apply on PR"
gh run view RUN_ID --log
```

---

## 🎯 When to Use This Workflow

### ✅ Use When:

- Making significant infrastructure changes
- Changing resource names (risk of conflicts)
- Adding new AWS services (risk of quota limits)
- Updating networking/security (high risk)
- Not sure if it will work (always!)

### ⚠️ Consider Skipping When:

- Tiny changes (like updating a tag value)
- Very confident (you've done it 100 times)
- Urgent hotfix (but still risky!)

**Recommendation**: Always use it! Takes 10 extra minutes but saves hours of debugging.

---

## 🔄 Workflow Comparison

| Aspect              | Old Workflow             | New Workflow            |
| ------------------- | ------------------------ | ----------------------- |
| **When Apply Runs** | After merge              | Before merge            |
| **Risk Level**      | High (PR already merged) | Low (can still cancel)  |
| **If Apply Fails**  | PR merged, must revert   | PR not merged, just fix |
| **Confidence**      | Hope it works            | Know it works           |
| **Time**            | Faster (risky)           | Slower (safe)           |
| **Recommended**     | No                       | **Yes!** ✅             |

---

## 🤔 FAQ

### Q: What if I forget to add the label?

**A**: Nothing bad happens! The plan still runs. You can add the label anytime before merging.

### Q: Can I test multiple times?

**A**: Yes! Remove and re-add the `test-apply` label to test again.

### Q: What if apply succeeds but I want to change something?

**A**: Make your changes, push, and test again. The infrastructure will update.

### Q: Does merging run apply again?

**A**: No! Once apply succeeds, the infrastructure is live. Merging just closes the PR.

### Q: What about rollback?

**A**: If you need to rollback:

```bash
# Option 1: Revert the PR
gh pr revert PR_NUMBER

# Option 2: Manual terraform destroy
cd terraform/s3-cloudfront
terraform destroy
```

### Q: Can I still use the old "merge then apply" workflow?

**A**: Yes, both workflows exist. But this one is much safer!

---

## 🔒 Safety Features

1. ✅ **Apply before merge** - see if it works first
2. ✅ **Full logs** - see exactly what failed
3. ✅ **Labels** - visual indication of status
4. ✅ **Comments** - detailed results in PR
5. ✅ **Artifacts** - logs saved for 30 days
6. ✅ **No auto-merge** - you control when to merge

---

## 📊 Success Metrics

After implementing this workflow:

- ✅ **100% confidence** before merging
- ✅ **Zero** failed merges
- ✅ **Faster recovery** from issues
- ✅ **Better sleep** at night! 😴

---

## 🎓 Best Practices

1. **Always test before merging** - Add the label every time
2. **Review the logs** - Don't just trust the green checkmark
3. **Test the URLs** - Actually verify it works
4. **Fix immediately** - If apply fails, fix it in the same PR
5. **Document changes** - Update this guide with learnings

---

## 📝 Troubleshooting

### Label doesn't trigger apply

**Check**:

- Label name is exactly `test-apply` (case-sensitive)
- Plan job completed successfully first
- Workflow file is on the branch

### Apply runs but doesn't comment

**Check**:

- Workflow permissions include `pull-requests: write`
- GitHub token has correct scopes
- PR is not from a fork (security limitation)

### Apply succeeds but infrastructure looks wrong

**Check**:

- Correct AWS account/region
- Terraform state is not corrupted
- No manual changes were made

---

## 🆘 Emergency Procedures

### If everything breaks:

```bash
# 1. Stop all workflows
gh run cancel RUN_ID

# 2. Check infrastructure state
cd terraform/s3-cloudfront
terraform state list
terraform show

# 3. Rollback if needed
terraform destroy -target=RESOURCE

# 4. Close the PR
gh pr close PR_NUMBER

# 5. Start fresh
git checkout main
git pull
git checkout -b fix/emergency-rollback
```

---

**Last Updated**: October 29, 2025  
**Workflow**: `terraform-plan-and-apply.yml`  
**Status**: Production Ready ✅
