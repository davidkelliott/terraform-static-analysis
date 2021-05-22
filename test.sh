test="dir/one dir/2"
for directory in ${test[@]}
do
  echo "Running TFSEC in ${directory}"
done
