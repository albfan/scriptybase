#!/bin/bash

#set -xv

function colorecholine() {
   echo -e -n "\x1b[$1m$2\x1b[m"
}

function colorecho() {
   echo -e "\x1b[$1m$2\x1b[m"
}

function help() {
   scriptname="$(basename $(readlink -f $0) .sh )"
   cat <<- EOF
   $scriptname launchs the test suite
   
      -v, --verbose     Show test execution
      -h, --help        Show this help
     
   Examples:
   
   $ $scriptname -v

EOF
}

OK=0
VERBOSE=1

# parse args {{{
TEMP=$(getopt -o "vh" -l verbose,help -n $(basename $0) -- "$@")

EXIT=$?
if [ $EXIT != 0 ]
then
   help
   exit $EXIT
fi

# process script arguments
eval set -- "$TEMP"

while true
do
   case "$1" in
      -v|--verbose)
         VERBOSE=0
         ;;
      -h|--help)
         help
         exit
         ;;
      --)
         shift
         break ;;
      *)
         cat <&2 <<EOF

Error, unknow arguments $1
EOF
         help
         exit 1
         ;;
   esac
   shift
done
# }}}
for test in t*.sh
do
   STATUS="$(colorecho 32 ok)"
   title=$(grep "###" $test | sed 's/^###\s*//')
   basenametest="$(basename $test .sh)"
   #create sandbox
   FIXTURE_DIR=$basenametest
   SANDBOX_DIR=$basenametest.tmp
   mkdir $SANDBOX_DIR
   if test "$VERBOSE" == 0
   then
      colorecholine 35 "$basenametest"
      echo -n :
      if test "$title" != ""
      then
         colorecho 36 " $title"
      fi
      ./$test "$FIXTURE_DIR" "$SANDBOX_DIR" |& tee "$basenametest.out"
   else
      ./$test "$FIXTURE_DIR" "$SANDBOX_DIR" &> "$basenametest.out"
   fi
   diff "$basenametest.ok" "$basenametest.out"
   if [ "$?" != 0 ]
   then
      echo "$test failed" >> suite.log
      OK=1
      STATUS="$(colorecho 31 failed)"
   fi
   rm -rf $SANDBOX_DIR

   colorecholine 35 "$basenametest"
   echo ", $STATUS"
   echo
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
