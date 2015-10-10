#!/bin/sh

# debug {{{
eval SCRIPT_DEBUG="\$$(basename $0 | tr - _)_DEBUG"
SCRIPT_DEBUG=${SCRIPT_DEBUG:--1}

if [ "$SCRIPT_DEBUG" -ge 1 ]
then
   set -x
fi
if [ "$SCRIPT_DEBUG" -ge 10 ]
then
   set -v
fi
#}}}

# functions {{{
function configSqlProgram() {
   if [ "$DATABASE_TYPE" == "sqlserver" ]
   then
      PROGRAM=sqlcmd
      COUNT_COMMAND='$PROGRAM -h -1 -d $DATABASE_NAME -b -W -Q "set nocount on; select count(*) from $UPDATE_TABLE where path=''$FILE''"'
      GET_SAVED_MD5_COMMAND='$PROGRAM -h -1 -d %DATABASE_NAME% -b -W -Q "set nocount on; select MD5SUM from databasechangelog where path='"'"'$FILE'"'"';'
      UPDATE_COMMAND='$PROGRAM -b -d $DATABASE_NAME -i $FILE'
      INSERT_FILE_PATH_COMMAND='$PROGRAM -d $DATABASE_NAME -Q "set nocount on; INSERT INTO $UPDATE_TABLE(md5sum, path, stamp) VALUES ('"'"'$MD5'"'"','"'"'$FILE'"'"',getdate());"'
      UPDATE_FILE_PATCH_COMMAND='$PROGRAM -d $DATABASE_NAME -Q "set nocount on; UPDATE $UPDATE_TABLE SET md5sum='"'"'$MD5'"'"',stamp=getdate() WHERE path='"'"'$FILE'"'"';"'
   elif [ "$DATABASE_TYPE" == "postgres" ]
   then
      PROGRAM=psql
   elif [ "$DATABASE_TYPE" == "mysql" ]
   then
      PROGRAM=mysql
   elif [ "$DATABASE_TYPE" == "sqlite" ]
   then
      PROGRAM=sqlite3
      COUNT_COMMAND='echo "select count(*) from $UPDATE_TABLE;"| $PROGRAM -bail $DATABASE_NAME'
      GET_SAVED_MD5_COMMAND='echo "select md5sum from databasechangelog where path='"'"'$FILE'"'"';" | $PROGRAM -bail $DATABASE_NAME'
      UPDATE_COMMAND='cat $FILE | $PROGRAM -bail $DATABASE_NAME'
      INSERT_FILE_PATH_COMMAND='echo "INSERT INTO $UPDATE_TABLE(md5sum, path, stamp) VALUES ('"'"'$MD5'"'"','"'"'$FILE'"'"','"'"'now'"'"');" | $PROGRAM -bail $DATABASE_NAME'
      UPDATE_FILE_PATCH_COMMAND='echo "UPDATE $UPDATE_TABLE SET md5sum='"'"'$MD5'"'"',stamp='"'"'now'"'"' WHERE path='"'"'$FILE'"'"';" | $PROGRAM -bail $DATABASE_NAME'
      CHECK_COMMAND='echo .tables | $PROGRAM $DATABASE_NAME | grep $UPDATE_TABLE'
   else
      #PROGRAM=sqlworkbenchcmd
      cat <<- EOF
      Unknown type $DATABASE_TYPE
EOF
      exit 1
   fi
}

function error() {
   cat <<- EOF
   Something goes wrong check output
EOF
   exit 1
}

function check() {
   configSqlProgram
   eval "$CHECK_COMMAND"
   if [ "$?" != 0 ]
   then
      colorecho 31 "Database not prepared"
   else
      cat <<- EOF
      Database $DATABASE_NAME is prepared.
EOF
      exit
   fi
}

function init() {
   configSqlProgram
   #TODO: Replace databasechangelog with configurable name
   cat $(dirname $(readlink -f $0))/res/$DATABASE_TYPE/init.sql | $PROGRAM -bail $DATABASE_NAME
   if [ "$?" != 0 ]
   then
      error
   else
      cat <<- EOF
      Database $DATABASE_NAME configured.
EOF
      exit
   fi
}

#
# Search directory looking for changes not upgraded
#
#   parameter 1: ROOT: initial project directory
#   parameter 2: DB_PATH: directory inside project to look for sql scripts
function processDir() {
ROOT=${1%/}
DB_PATH="$ROOT/${2%/}"

echo

colorecho 34 "- Inspecting $DB_PATH"
echo
for FILE in $DB_PATH/*.$EXTENSION
do
   if ! [ -f "$FILE" ]
   then 
      continue
   fi
   colorecho 33 "patch $FILE:"
   count=$(eval "$COUNT_COMMAND")
   if [ "$?" != 0 ]
   then
      colorecho 31 "Error checking patch updated"
      cat <<- EOF

      Please configure database with

      $ $0 -t <database_type> -d <databaseName> --init
EOF
      exit 1
   fi
   UPDATE=
   if [ "$count" == "0" ]
   then
      UPDATE=1
      echo "   new script"
      echo
      if [ -z "$AUTO" ]
      then
         read -p "Do you want to see the new file $FILE (Y/[N])? " SHOWFILE
         echo
      else
         SHOWFILE=$AUTO
      fi
      if [ "$SHOWFILE" == "Y" ]
      then
         echo --
         echo -- $FILE
         echo --
         cat "$FILE"
         echo
      fi

      if [ -z "$AUTO" ]
      then
         read -p "Do you want to upgrade the new file $FILE (Y/[N])? " PASSFILE
         echo
      else
         PASSFILE=$AUTO
      fi
      if [ "$PASSFILE" == "Y" ]
      then
         eval "$UPDATE_COMMAND"
         if [ "$?" != 0 ]
         then
            error
         fi
      fi 
      MD5=$(md5sum "$FILE" | awk '{print $1}')
   else
      if [ "$count" == "1" ] 
      then
         #compare md5 to see if something changed
         MD5=$(md5sum $FILE | awk '{print $1}')
         DATA_MD5=$(eval "$GET_SAVED_MD5_COMMAND")
         if [ "$MD5" == "$DATA_MD5" ]
         then
            echo
            colorecho 32 "   patch $FILE is updated on $DATABASE_NAME"
            echo
         else
            echo Changes in the file $FILE. Searching in git hash md5 $DATA_MD5
            #TODO: Config
            echo Limited to 100 revs
            echo
            for x in $(seq 0 1 100) 
            do 
               MD5_GIT=$(git -C $ROOT show HEAD~$x:./$FILE 2>/dev/null | md5sum | awk '{print $1}')
               if [ "$MD5_GIT" == "$DATA_MD5" ] 
               then
                  #TODO: Extract differences without +, - and @@
                  echo comparing file $FILE 
                  HEAD_HASH=$(git -C $ROOT rev-parse HEAD)
                  UPTODATE_HASH=$(git -C $ROOT rev-parse HEAD~$x)
                  echo "between $UPTODATE_HASH and (HEAD)"
                  echo
                  echo command: git -C $ROOT diff --color --word-diff --ignore-blank-lines -w -b --ignore-space-at-eol $UPTODATE_HASH HEAD -- $FILE 
                  git --no-pager -C $ROOT diff --color --word-diff --ignore-blank-lines -w -b --ignore-space-at-eol $UPTODATE_HASH HEAD -- $FILE 
                  echo
                  UPDATE=1
                  break
               fi
            done
            #If UPDATE is not assigned original file was not founded which is a problem
            if [ "$UPDATE" != "1" ]
            then
               echo Updated file not found
               echo
               exit 1
            fi 
         fi 
      else
         if [ "$count" > 1 ]
         then
            echo "more than one match with $FILE ($count)"
	      else
            echo "errors processing upgrade from $FILE"
         fi
         return
      fi 
   fi 
   if [ "$UPDATE" == "1" ]
   then
      #TODO: This should be passed to a function
      if [ -z "$AUTO" ]
      then
         read -p "Was the file updated (Y/[N])? " ISUPDATED
         echo
      else
         ISUPDATED=$AUTO
      fi
      if [ "$ISUPDATED" == "Y" ]
      then
         if [ "$count" == "0" ]
         then
            echo inserting in changes table $FILE, $MD5
            eval $INSERT_FILE_PATH_COMMAND
         else
            echo updated hash $MD5 in file $FILE
            eval $UPDATE_FILE_PATCH_COMMAND
         fi 
         echo
      fi 
   fi 
done
}

function help() {
   scriptname=$(basename $(readlink -f $0) .sh )
   cat <<- EOF
   $scriptname Help you keep your database uptodate
   
      -t, --database-type     Choose database
      -d, --database-name     database name or connection url
      -r, --root              project root
      -p, --patch-dir         relative path from project root to patches
      -a, --auto              Autoresponse. (batch mode)
          --check             Chek if scriptybase is installed
          --init              Initialize scriptybase stuff
     
   Examples:
   
   $ $scriptname -t sqlite -d test.db -r . -p patches

EOF
}

function colorecho() {
   echo -e "\x1b[$1m$2\x1b[m"
}
#}}}

if [ $# == 0 ]
then
   echo wrong number of arguments
   help
   exit 1
fi

#TODO: Configure from command line

EXTENSION=sql

UPDATE_TABLE="databasechangelog"

# parse args {{{
TEMP=$(getopt -o "t:d:r:p:a::h" -l database-type:,database-name:,root:,patch-dir:,auto::,check,init,help -n $(basename $0) -- "$@")

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
      -t|--database-type)
         DATABASE_TYPE=$2
         shift
         ;;
      -d|--database-name) 
         DATABASE_NAME=$2
         shift
         ;;
      -r|--root) 
         ROOT=$2
         shift
         ;;
      -p|--patch-dir) 
         DB_PATH=$2
         shift
         ;;
      -a|--auto) 
         AUTO=$2
         if [ "$AUTO" == "" ]
         then
            AUTO="N"
         fi
         shift
         ;;
      --check)
         check
         exit
         ;;
      --init)
         init
         exit
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


configSqlProgram 

processDir $ROOT $DB_PATH

colorecho 34 "- Update completed"
echo

