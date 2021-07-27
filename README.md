# Terraform Static Analysis Action

This action combines both [TFSEC](https://github.com/tfsec/tfsec) and [Checkov](https://github.com/bridgecrewio/checkov) into one action, loosely based on the [TFSEC action](https://github.com/triat/terraform-security-scan) and [Checkov actions](https://github.com/bridgecrewio/checkov-action) here.

The main reason for combining these is to add logic to perform different scan options:

Full scan - scan all folders with `*.tf` files in a repository.

Changes only - scan only folders with `*.tf` files that have had changes since the last commit.

Single folder - standard scan of a given folder.

## Example

```
jobs:
  terraform-static-analysis:
    name: Terraform Static Analysis
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v2.3.4
      with:
        fetch-depth: 0
    - name: Run Analysis
      uses: davidkelliott/terraform-static-analysis@main
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        scan_type: changed
```