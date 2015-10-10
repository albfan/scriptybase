
### check sqlite client is installed

which sqlite3 &>/dev/null

if [ "$?" != 0 ]
then
   echo sqlite not installed
   exit 1
else
   echo sqlite correctly installed
fi
