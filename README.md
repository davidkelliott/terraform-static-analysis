# Terraform Static Analysis Action

*I have moved this Action to here now - https://github.com/ministryofjustice/github-actions/tree/main/terraform-static-analysis


This action combines [TFSEC](https://github.com/tfsec/tfsec), [Checkov](https://github.com/bridgecrewio/checkov) and [tflint](https://github.com/terraform-linters/tflint) into one action, loosely based on the [TFSEC action](https://github.com/triat/terraform-security-scan) and [Checkov actions](https://github.com/bridgecrewio/checkov-action) here.

The main reason for combining these is to add logic to perform different scan options for repos with multiple Terraform folders:

Full scan (`full`) - scan all folders with `*.tf` files in a repository.

Changes only (`changed`) - scan only folders with `*.tf` files that have had changes since the last commit.

Single folder (`single`) - standard scan of a given folder.

See the [action.yml](action.yml) for other input options.

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
