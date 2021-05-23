test="dir/one dir/2"
for directory in ${test[@]}
do
  echo "Running TFSEC in ${directory}"
done

tfsec_exitcode=1
checkov_exitcode=1

if [ $tfsec_exitcode -gt 0 ] || [ $checkov_exitcode -gt 0 ];then
  echo "above 0"
  exit 1
else
  echo "equals 0"
  exit 0
fi

