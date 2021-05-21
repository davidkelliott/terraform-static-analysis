#!/bin/bash

# set working directory
if [ "${INPUT_TERRAFORM_WORKING_DIR}" != "" ] && [ "${INPUT_TERRAFORM_WORKING_DIR}" != "." ]; then
  TERRAFORM_WORKING_DIR="/github/workspace/${INPUT_TERRAFORM_WORKING_DIR}"
else
  TERRAFORM_WORKING_DIR="/github/workspace/"
fi

# grab tfsec from GitHub (taken from README.md)
if [[ -n "$INPUT_TFSEC_VERSION" ]]; then
  env GO111MODULE=on go install github.com/tfsec/tfsec/cmd/tfsec@"${INPUT_TFSEC_VERSION}"
else
  env GO111MODULE=on go get -u github.com/tfsec/tfsec/cmd/tfsec
fi

TF_DIRECTORIES_WITH_CHANGES=`git diff --no-commit-id --name-only -r HEAD^ | awk '{print $1}' | grep '.tf' | sed 's#/[^/]*$##' | uniq`
echo $TF_DIRECTORIES_WITH_CHANGES

for directory in $TF_DIRECTORIES_WITH_CHANGES
do
    echo $directory
done

if [[ -n "$INPUT_TFSEC_EXCLUDE" ]]; then
  TFSEC_OUTPUT=$(/go/bin/tfsec ${TERRAFORM_WORKING_DIR} --no-colour -e "${INPUT_TFSEC_EXCLUDE}" ${INPUT_TFSEC_OUTPUT_FORMAT:+ -f "$INPUT_TFSEC_OUTPUT_FORMAT"} ${INPUT_TFSEC_OUTPUT_FILE:+ --out "$INPUT_TFSEC_OUTPUT_FILE"})
else
  TFSEC_OUTPUT=$(/go/bin/tfsec ${TERRAFORM_WORKING_DIR} --no-colour ${INPUT_TFSEC_OUTPUT_FORMAT:+ -f "$INPUT_TFSEC_OUTPUT_FORMAT"} ${INPUT_TFSEC_OUTPUT_FILE:+ --out "$INPUT_TFSEC_OUTPUT_FILE"})
fi
TFSEC_EXITCODE=${?}

echo "Running Checkov"
CHECKOV_OUTPUT=$(checkov --quiet -d $TERRAFORM_WORKING_DIR)
CHECKOV_EXITCODE=$?

# Exit code of 0 indicates success.
if [ ${TFSEC_EXITCODE} -eq 0 ]; then
  TFSEC_STATUS="Success"
else
  TFSEC_STATUS="Failed"
fi

if [ ${CHECKOV_EXITCODE} -eq 0 ]; then
  CHECKOV_STATUS="Success"
else
  CHECKOV_STATUS="Failed"
fi

# Print output.
echo "${TFSEC_OUTPUT}"
echo "${CHECKOV_OUTPUT}"

# Comment on the pull request if necessary.
if [ "${INPUT_TFSEC_ACTIONS_COMMENT}" == "1" ] || [ "${INPUT_TFSEC_ACTIONS_COMMENT}" == "true" ]; then
  TFSEC_COMMENT=1
else
  TFSEC_COMMENT=0
fi

if [ "${GITHUB_EVENT_NAME}" == "pull_request" ] && [ -n "${GITHUB_TOKEN}" ] && [ "${TFSEC_COMMENT}" == "1" ] && [ "${TFSEC_EXITCODE}" != "0" ]; then
    COMMENT="#### \`TFSEC Scan\` ${TFSEC_STATUS}
<details><summary>Show Output</summary>

\`\`\`hcl
${TFSEC_OUTPUT}
\`\`\`

</details>

#### \`Checkov Scan\` ${CHECKOV_STATUS}
<details><summary>Show Output</summary>

\`\`\`hcl
${CHECKOV_OUTPUT}
\`\`\`

</details>"
  PAYLOAD=$(echo "${COMMENT}" | jq -R --slurp '{body: .}')
  URL=$(jq -r .pull_request.comments_url "${GITHUB_EVENT_PATH}")
  echo "${PAYLOAD}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${URL}" > /dev/null
fi

if [ "${TFSEC_EXITCODE}" != "0" ] || [  "${CHECKOV_EXITCODE}" != "0" ];then
  exit 1
else
  exit 0
fi
