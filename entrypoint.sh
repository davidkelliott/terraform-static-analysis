#!/bin/bash

# grab tfsec from GitHub (taken from README.md)
if [[ -n "$INPUT_TFSEC_VERSION" ]]; then
  env GO111MODULE=on go install github.com/tfsec/tfsec/cmd/tfsec@"${INPUT_TFSEC_VERSION}"
else
  env GO111MODULE=on go get -u github.com/tfsec/tfsec/cmd/tfsec
fi

line_break() {
  echo
  echo "*****************************"
  echo
}

declare -i tfsec_exitcode=0
declare -i checkov_exitcode=0

tf_folders_with_changes=`git diff --no-commit-id --name-only -r @^ | awk '{print $1}' | grep '.tf' | sed 's#/[^/]*$##' | uniq`
echo "TF folders with changes"
echo $tf_folders_with_changes

all_tf_folders=`find . -type f -name '*.tf' | sed 's#/[^/]*$##' | sed 's/.\///'| sort | uniq`
echo "All TF folders"
echo $all_tf_folders

run_tfsec(){
  echo "TFSEC will check the following folders:"
  echo $1
  directories=($1)
  for directory in ${directories[@]}
  do
    echo "Running TFSEC in ${directory}"
    terraform_working_dir="/github/workspace/${directory}"
    if [[ -n "$INPUT_TFSEC_EXCLUDE" ]]; then
      /go/bin/tfsec ${terraform_working_dir} --no-colour -e "${INPUT_TFSEC_EXCLUDE}" ${INPUT_TFSEC_OUTPUT_FORMAT:+ -f "$INPUT_TFSEC_OUTPUT_FORMAT"} ${INPUT_TFSEC_OUTPUT_FILE:+ --out "$INPUT_TFSEC_OUTPUT_FILE"}
    else
      /go/bin/tfsec ${terraform_working_dir} --no-colour ${INPUT_TFSEC_OUTPUT_FORMAT:+ -f "$INPUT_TFSEC_OUTPUT_FORMAT"} ${INPUT_TFSEC_OUTPUT_FILE:+ --out "$INPUT_TFSEC_OUTPUT_FILE"}
    fi
    tfsec_exitcode+=$?
    echo "tfsec_exitcode=${tfsec_exitcode}"
  done
  return $tfsec_exitcode
}

run_checkov(){
  echo "Checkov will check the following folders:"
  echo $1
  directories=($1)
  for directory in ${directories[@]}
  do
    echo "Running Checkov in ${directory}"
    terraform_working_dir="/github/workspace/${directory}"
    
    checkov --quiet -d $terraform_working_dir
    checkov_exitcode+=$?
    echo "checkov_exitcode=${checkov_exitcode}"
  done
  return $checkov_exitcode
}

case ${INPUT_SCAN_TYPE} in

  full)
    line_break
    echo "Starting full scan"
    TFSEC_OUTPUT=$(run_tfsec "${all_tf_folders}")
    tfsec_exitcode=$?
    CHECKOV_OUTPUT=$(run_checkov "${all_tf_folders}")
    checkov_exitcode=$?
    ;;

  changed)
    line_break
    echo "Starting scan of changed folders"
    TFSEC_OUTPUT=$(run_tfsec "${tf_folders_with_changes}")
    CHECKOV_OUTPUT=$(run_checkov "${tf_folders_with_changes}")
    ;;
  *)
    line_break
    echo "Starting single folder scan"
    TFSEC_OUTPUT=$(run_tfsec "${INPUT_TERRAFORM_WORKING_DIR}")
    CHECKOV_OUTPUT=$(run_checkov "${INPUT_TERRAFORM_WORKING_DIR}")
    ;;
esac

if $tfsec_success; then
  TFSEC_STATUS="Success"
else
  TFSEC_STATUS="Failed"
fi

if $checkov_success; then
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

if [ "${GITHUB_EVENT_NAME}" == "pull_request" ] && [ -n "${GITHUB_TOKEN}" ] && [ "${TFSEC_COMMENT}" == "1" ] ; then
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

echo $tfsec_exitcode
echo $checkov_exitcode

if [ $tfsec_exitcode -gt 0 ] || [ $checkov_exitcode -gt 0 ];then
  echo "Exiting with error"  
  exit 1
else
  echo "Exiting with no error"  
  exit 0
fi
