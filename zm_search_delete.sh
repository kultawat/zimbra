#!/bin/bash

## Written by Chris Franklin
##  CFranklin@NomadCF.com

## Vars
DOMAIN=asiainsurance.co.th
MSG_LIST_MAX=999
LOG=/tmp/zimbra_remove_messages.$(date +%s).log

## Nothing to edit passed here

function _help() {
    cat <<EOF
 $1
 
 -a : Finds emails with any attachment
      $0 -a 
 -A : attachment filename 
      $0 -A bob.txt
      finds emai lwith wav attachments
      $0 -A .wav

 -c : Contains this word/phrase (very picky)
      $0 -c BPMCLASSROOM
      !! Won't find BPMCLASSROOM !!
      $0 -c BPMCLASS

 -C : Condition ("unread", "read", "flagged", "unflagged", "sent", "draft", "received", "replied", "unreplied", "forwarded", unforwarded", "anywhere", "remote" (in a shared folder), "local", "sent", "invite", "solo" (no other messages in conversation), "tome", "fromme", "ccme", "tofromme". "fromccme", "tofromccme" (to, from cc me, including my aliases)
      $0 -C unread
     
 -d : recived on date  (must be as fallows mm/dd/yyyy)
      $0 -d 09/09/2017
 -D : today
      $0 -D 
 -e : Before this date (must be as fallows mm/dd/yyyy)
      $0 -e 09/09/2018
 -E : After this date  (must be as fallows mm/dd/yyyy)
      $0 -E 09/09/2017

 -f : From address (Display name,emailaddress or domain) (Always Wild card searches!!) 
      $0 -f cfranklin
      $0 -f "Chris Franklin"
      $0 -f @berea.k12.oh.us
      $0 -f cfranklin@berea.k12.oh.us

 -h : Header exists (Any value is * (wildcard))
      $0 -h "X-Spammy"
 -H : Header Value (Requires -h)
      $0 -H "75"

 -i : Search only the inbox (Default is to search all folders OR -l messages)
      $0 -i
 -I : folder to search in (Default is to search all folders OR -l messages)
      $0 -I Sent

 -l : Limit List to this number newest messages
      $0 -l 5
  
 -L : List user messages (max 999)
      $0 -L

 -m : Move Message to trash (Default is to show messages)
      $0 -m

 -s : Subject
      $0 -s "Taxes are due"

 -S : Messages total size including attachments is BIGGER than (in megabytes)
      $0 -S 5

 -t : Message for (to or cc)
      $0 -t "bob@aol.com"

 -u : Username to check (Default is all usernames)
      $0 -u "cfranklin"

 -v : Verbose 
 
 -Z : Deletes the matching messages
       

--------------

Examples:
  Find emails with the fallowing 
   1. delivered "TODAY"
   2. HEADER field called "Return-Path" WITH value of "geofdupo@savba.sk" 
   3. FROM a display name containing "BCSD"
   4. Message Contains the phrase "BCSD Account will be De-activated"
   5. Subject Contains "Technology Help Desk"
   6. Search in the inbox
   7. Search only the mailbox for USER cfranklin 

   $0 -D -h "Return-Path" -H "geofdupo@savba.sk" -f "BCSD" -c "BCSD Account will be De-activated" -s "Technology Help Desk" -i -u cfranklin

  As as above, but now MOVE the email to the TRASH
 
   $0 -D -h "Return-Path" -H "geofdupo@savba.sk" -f "BCSD" -c "BCSD Account will be De-activated" -s "Technology Help Desk" -i -u cfranklin -m

 -------------

 $1

EOF
    exit 1
}

REQ=0
MSG_LIST=0
SEARCH=0
MOVE=0
DELETE=0
DEBUG=0
while getopts ":A:c:C:d:e:E:f:h:l:H:I:N:s:S:t:u:miLaDZv" opt; do
    case ${opt} in
    a)
        EMAIL_ATTACHMENT=1
        SEARCH=1
        REQ=1
        ;;
    A)
        EMAIL_ATTACHMENT_NAME="${OPTARG}"
        SEARCH=1
        REQ=1
        ;;
    t)
        SEARCH=1
        EMAIL_TO="${OPTARG}"
        REQ=1
        ;;
    c)
        SEARCH=1
        EMAIL_CONTAINS="${OPTARG}"
        REQ=1
        ;;
    C)
        SEARCH=1
        EMAIL_CONDITION="${OPTARG}"
        REQ=1
        ;;
    l)
        MSG_LIST_MAX=${OPTARG}
        ;;
    d)
        SEARCH=1
        EMAIL_DATE="${OPTARG}"
        REQ=1
        ;;
    D)
        SEARCH=1
        EMAIL_DATE="$(date +%m/%d/%Y)"
        REQ=1
        ;;
    e)
        SEARCH=1
        EMAIL_DATE_BEFORE="${OPTARG}"
        REQ=1
        ;;
    E)
        SEARCH=1
        EMAIL_DATE_AFTER="${OPTARG}"
        REQ=1
        ;;
    f)
        SEARCH=1
        EMAIL_FROM="${OPTARG}"
        REQ=1
        ;;
    h)
        SEARCH=1
        EMAIL_HEADER="#${OPTARG}"
        REQ=1
        ;;
    H)
        SEARCH=1
        EMAIL_HEADER_VALUE="${OPTARG}"
        REQ=1
        ;;
    i)
        SEARCH_FOLDER="inbox"
        REQ=1
        ;;
    L)
        MSG_LIST=1
        REQ=1
        ;;
    I)
        SEARCH_FOLDER="${OPTARG}"
        REQ=1
        ;;
    m)
        MOVE=1
        ;;
    s)
        SEARCH=1
        EMAIL_SUBJECT="${OPTARG}"
        REQ=1
        ;;
    S)
        SEARCH=1
        EMAIL_SIZE_BIGGER=">${OPTARG}mb"
        REQ=1
        ;;
    u)
        EMAIL_USER="${OPTARG}"
        ;;
    v)
        DEBUG=1
        ;;
    Z)
        DELETE=1
        ;;
    \?)
        _help $opt
        ;;
    :)
        _help $opt
        ;;
    *)
        _help $opt
        ;;
    esac
done

shift $((OPTIND - 1))

if [ $REQ -eq 0 ] && [ ! -z "${EMAIL_USER}" ]; then
    MSG_LIST=1
    REQ=1
fi

if [ $REQ -eq 0 ]; then
    _help
fi

if [ -z "${EMAIL_USER}" ]; then
    EMAIL_USER="*"
fi

if [ ! -z "${EMAIL_DATE}" ]; then
    if [ ! -z "${EMAIL_DATE_BEFORE}" ] || [ ! -z "${EMAIL_DATE_AFTER}" ]; then
        _help "ERROR: -d CAN'T be used with -D OR -E "
    fi
fi

if [ $DELETE -eq 1 ] && [ $MOVE -eq 1 ]; then
    _help "ERROR: -Z CAN'T be used with -m"
fi

#convert LIST anything to listing with a search
if [ $MSG_LIST -eq 1 ] && [ $SEARCH -eq 1 ]; then
    MSG_LIST=2
elif [ $MOVE -eq 0 ] && [ $DELETE -eq 0 ] && [ $MSG_LIST -eq 0 ]; then
    MSG_LIST=2
fi

if [ $MSG_LIST -gt 0 ] && [ $MOVE -eq 1 ]; then
    _help "ERROR: -m and -L can NOT be used at the same time."
fi

if [ $MSG_LIST -gt 0 ] && [ $DELETE -eq 1 ]; then
    _help "ERROR: -Z and -L can NOT be used at the same time."
fi

if [ ! -z "${EMAIL_HEADER_VALUE}" ] && [ -z "${EMAIL_HEADER}" ]; then
    _help "ERROR: -H requires -h"
fi

if [ ! -z "${EMAIL_ATTACHMENT_NAME}" ] && [ ! -z "${EMAIL_ATTACHMENT}" ]; then
    _help "ERROR: -A Can't BOTH be used -a"
fi

START_DATE="$(date)"
START_SECS=$(date +%s)

## Lookup zmlocalconfig
ZMCONFIG=$(whereis zmlocalconfig | cut -d ' ' -f2)
if [ ! -e "${ZMCONFIG}" ]; then
    echo "Could not find: zmlocalconfig"
    exit
fi

## lookup ldapsearch
LDAPSEARCH=$(whereis ldapsearch | cut -d ' ' -f2)
if [ ! -e "${LDAPSEARCH}" ]; then
    echo "Could not find: ldapsearch"
    exit
fi

# MAIL=$(which mail)
# if [ ! -e "${MAIL}" ]; then
#     echo "Could not find: mail"
#     exit
# fi

EMAIL_SEARCH=""

if [ ! -z "${EMAIL_FROM}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH}from:${EMAIL_FROM} "
fi

if [ ! -z "${EMAIL_SUBJECT}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH}subject:\"${EMAIL_SUBJECT}\" "
fi

if [ ! -z "${EMAIL_DATE}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH}date:${EMAIL_DATE} "
fi

if [ ! -z "${EMAIL_DATE_BEFORE}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH}before:${EMAIL_DATE_BEFORE} "
fi

if [ ! -z "${EMAIL_DATE_AFTER}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH}after:${EMAIL_DATE_AFTER} "
fi

if [ ! -z "${SEARCH_FOLDER}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH}in:${SEARCH_FOLDER} "
fi

if [ ! -z "${EMAIL_HEADER_VALUE}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH} ${EMAIL_HEADER}:\"${EMAIL_HEADER_VALUE}\" "
fi

if [ ! -z "${EMAIL_TO}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH} (to:${EMAIL_TO} OR cc:${EMAIL_TO}) "
fi

if [ ! -z "${EMAIL_ATTACHMENT}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH}has:attachment "
fi

if [ ! -z "${EMAIL_ATTACHMENT_NAME}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH}filename:\"${EMAIL_ATTACHMENT_NAME}\" "
fi

if [ ! -z "${EMAIL_CONTAINS}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH}content:\"${EMAIL_CONTAINS}\" "
fi

if [ ! -z "${EMAIL_SIZE_BIGGER}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH}larger:${EMAIL_SIZE_BIGGER} "
fi

if [ ! -z "${EMAIL_CONDITION}" ]; then
    EMAIL_SEARCH="${EMAIL_SEARCH}is:${EMAIL_CONDITION} "
fi

## This is the default ldap lookup query
LDAP_SEARCH="${LDAPSEARCH} -x -h $($ZMCONFIG ldap_host | cut -d '=' -f2) -D $($ZMCONFIG zimbra_ldap_userdn | awk '{print $3}') -w$($ZMCONFIG -s zimbra_ldap_password | cut -d ' ' -f3) -LLL -o ldif-wrap=no "

echo ""

if [ $DELETE -eq 1 ] || [ $MOVE -eq 1 ]; then
    echo "Log file: ${LOG}"
fi

echo ""

$LDAP_SEARCH "(&(objectClass=zimbraAccount)(mail=${EMAIL_USER}@${DOMAIN}))" mail | while IFS=": " read TRASH EMAIL; do
    if [ ! -z "${EMAIL}" ] && [ "${TRASH}" == "mail" ]; then
        # MNUM  = Message number in printed out list
        # MID   = Message ID in zimbra
        # TRASH = Everything else about the email

        if [ $DELETE -eq 1 ] || [ $MOVE -eq 1 ]; then
            echo "${EMAIL}" | tee -a "${LOG}"
        else
            echo "${EMAIL}"
        fi

        if [ $MSG_LIST -eq 1 ]; then
            if [ "${DEBUG}" -eq 1 ]; then
                echo "/opt/zimbra/bin/zmmailbox -z -m '${EMAIL}' s -l ${MSG_LIST_MAX} -T" >>"${LOG}"
            fi
            /opt/zimbra/bin/zmmailbox -z -m "${EMAIL}" s -l ${MSG_LIST_MAX} -T | tee -a "${LOG}"
        elif [ $MSG_LIST -eq 2 ]; then
            if [ "${DEBUG}" -eq 1 ]; then
                echo "/opt/zimbra/bin/zmmailbox -z -m '${EMAIL}' s -l ${MSG_LIST_MAX} -t message '${EMAIL_SEARCH}'" >>"${LOG}"
            fi
            /opt/zimbra/bin/zmmailbox -z -m "${EMAIL}" s -l ${MSG_LIST_MAX} -t message "${EMAIL_SEARCH}" | tee -a "${LOG}"
        elif [ $MOVE -eq 1 ] || [ $DELETE -eq 1 ]; then
            if [ "${DEBUG}" -eq 1 ]; then
                echo "/opt/zimbra/bin/zmmailbox -z -m '${EMAIL}' s -l ${MSG_LIST_MAX} -t message '${EMAIL_SEARCH}'" | tee -a "${LOG}"
            fi
            /opt/zimbra/bin/zmmailbox -z -m "${EMAIL}" s -l ${MSG_LIST_MAX} -t message "${EMAIL_SEARCH}" | while IFS=" " read MNUM MID TRASH; do
                if [ ! -z "${MNUM}" ] && [ ! -z "${MID}" ]; then
                    if [ "${MNUM//./}" != "${MNUM}" ]; then
                        if [ $DELETE -eq 1 ]; then
                            echo "#Deleting Match: ${EMAIL} => ${MNUM} => ${MID} => ${TRASH} " >>"${LOG}"
                            echo "/opt/zimbra/bin/zmmailbox -z -m '${EMAIL}' deleteMessage '${MID}'" >>"${LOG}"
                            echo "Deleting ${MID} for ${EMAIL}"
                            /opt/zimbra/bin/zmmailbox -z -m "${EMAIL}" deleteMessage "${MID}"
                        else
                            echo "#Moving Match: ${EMAIL} => ${MNUM} => ${MID} => ${TRASH} " >>"${LOG}"
                            echo "#undo: /opt/zimbra/bin/zmmailbox -z -m '${EMAIL}' mm '${MID}' /${SEARCH_FOLDER}" >>"${LOG}"
                            echo /opt/zimbra/bin/zmmailbox -z -m "${EMAIL}" mm "${MID}" /Trash >>"${LOG}"
                            echo "Moving msg ${MID} for ${EMAIL} to TRASH"
                            /opt/zimbra/bin/zmmailbox -z -m "${EMAIL}" mm "${MID}" /Trash
                        fi
                    fi
                fi
            done
        fi
    fi
done

FINISHED_DATE="$(date)"
FINISHED_SECS=$(date +%s)

echo ""
echo ""
echo "Started: ${START_DATE}" | tee -a "${LOG}"
echo "Finished: ${FINISHED_DATE}" | tee -a "${LOG}"

if [ $DELETE -eq 1 ] || [ $MOVE -eq 1 ]; then
    echo "Run time: $((($FINISHED_SECS - $START_SECS) / 60)) mins" | tee -a "${LOG}"
else
    echo "Run time: $((($FINISHED_SECS - $START_SECS) / 60)) mins"
fi

echo ""
exit 0
