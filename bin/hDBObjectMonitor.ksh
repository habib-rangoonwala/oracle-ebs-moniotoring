#!/bin/ksh

###############################################################
#	Author: 	Habib Rangoonwala
#	Creation Date:	04-Jun-2009
#	Updation Date:	
###############################################################

# define Alert Title
hMailAlertTitle="DB Object Monitor [Mail Alert]"
hPageAlertTitle="DB Object Monitor [Page Alert]"

# source the main environment file
hDirName=`dirname $0`
. $hDirName/hInitialize.ksh "$0"
if [ $? -eq 1 ]; then
	exit 1
fi

# source SQLPlus environment
. $hDirName/hInitializeSQLPlus.ksh
if [ $? -eq 1 ]; then
	`WriteLogFile $hScriptLogFile "Unable to Load SQLPlus environment $hNewLine" "$hDateFormat"`
	exit 1
fi

# Read Script Specific Configuration Parameter
hSQL1=`GetScriptParameter "$hInstance" "$hHost" "$H_SCRIPTSECTION" "SQL1"`

#run SQLPlus
hSQLPlusOutput=`RunSQLCommand "$hCredentials" "$hSQL1" "$hSQLPlusExecutable" "$hTemporaryFile"`

if [ $? -eq 1 ]; then

	`WriteLogFile $hScriptLogFile "Following error occurred $hNewLine" "$hDateFormat"`
	`WriteLogFile $hScriptLogFile "$hSQLPlusOutput" "$hDateFormat"`

	`WriteLogFile $hScriptLogFile "Sending Alert to $hPageAlias $hNewLine" "$hDateFormat"`
	`SendSingleLineEmail "$hTemporaryFile" "$hFromAlias" "$hPageAlias" "FAILED:$hMailSubject" "$hPageAlertTitle" "$hSQLPlusOutput"`
	`WriteLogFile $hScriptLogFile "Alert Sent to $hPageAlias $hNewLine" "$hDateFormat"`

	exit 1

fi

hMailErrorCount=0
printf "Owner\tObject Type\tObject Name\tCreated\tLast DDL Time\n" > $hTemporaryFile

cat $hSQLPlusOutFile|while read LINE;
do

	if [ ! -z "$LINE" ]; then

		hOwner=`GetColumnValue "$LINE" "1"`
		hObjectType=`GetColumnValue "$LINE" "2"`
		hObjectName=`GetColumnValue "$LINE" "3"`
		hCreated=`GetColumnValue "$LINE" "4"`
		hLastDDLTime=`GetColumnValue "$LINE" "5"`

		printf "$hOwner\t$hObjectType\t$hObjectName\t$hCreated\t$hLastDDLTime\n" >> $hTemporaryFile

		hMailErrorCount=`expr $hMailErrorCount + 1`
		
	fi
	
done

if [ -f $hSQLPlusOutFile ]; then
	rm $hSQLPlusOutFile
fi

if [ "$hMailErrorCount" -gt 0 ]; then
	`WriteLogFile $hScriptLogFile "Mail Alert Count $hMailErrorCount $hNewLine" "$hDateFormat"`
	`WriteLogFile $hScriptLogFile "Sending Alert to $hMailAlias $hNewLine" "$hDateFormat"`
	`SendMultiLineEmail "$hTemporaryFile" "$hFromAlias" "$hMailAlias" "$hMailSubject" "$hMailAlertTitle [Object Count=$hMailErrorCount]" "5"` 
	`WriteLogFile $hScriptLogFile "Alert Sent to $hMailAlias $hNewLine" "$hDateFormat"`
else
	`WriteLogFile $hScriptLogFile "No Mail Alert $hNewLine" "$hDateFormat"`
	rm "$hTemporaryFile"
fi

`WriteLogFile $hScriptLogFile "Script completed $hNewLine" "$hDateFormat"`

# truncate log file <hScriptLogFileSize> lines
tail "-$hScriptLogFileSize" $hScriptLogFile > $hTemporaryFile
mv $hTemporaryFile $hScriptLogFile
exit 0
