#!/bin/bash

#set -xv
OK=0
VERBOSE=0

for test in t*.sh
do
   STATUS="ok"
   title=$(grep "###" $test | sed 's/^###\s*//')
   basenametest="$(basename $test .sh)"
   #create sandbox
   FIXTURE_DIR=$basenametest
   SANDBOX_DIR=$basenametest.tmp
   mkdir $SANDBOX_DIR
   ./$test "$FIXTURE_DIR" "$SANDBOX_DIR" &> "$basenametest.out"
   diff "$basenametest.ok" "$basenametest.out"
   if [ "$?" != 0 ]
   then
      echo "$test failed" >> suite.log
      OK=1
      STATUS="failed"
   fi
   rm -rf $SANDBOX_DIR

   if test "$VERBOSE" == 0
   then
      if test "$title" != ""
      then
         echo $basenametest: $title, $STATUS
      else
         echo $basenametest, $STATUS
      fi
   fi
done

echo
   
if [ $OK != 0 ]
then
   echo some test failed:
   cat suite.log
   rm suite.log
else
   echo test suite passed correctly
fi

rm -rf t*.tmp suite.log t*.out

exit $OK
