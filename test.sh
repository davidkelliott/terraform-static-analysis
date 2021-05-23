test="dir/one dir/2"
for directory in ${test[@]}
do
  echo "Running TFSEC in ${directory}"
done

testtrue=true
echo "Test true:"
echo $testtrue
testfalse=false
echo "Test false:"
echo $testfalse
testtrue=`[ $testtrue ] && [ $testfalse ]`
echo "testtrue should be false:"
echo $testtrue

