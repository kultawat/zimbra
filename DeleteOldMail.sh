#!/bin/bash

# Delete mails before this date MM/DD/YY 
THEDATE='02/01/20'
DOMAIN='asiainsurance.co.th'

for account in `zmprov -l gaa $DOMAIN`;
do
    echo "$account"
    for i in `zmmailbox -z -m $account search -l 1000 --types conversation before:$THEDATE | sed '/^$/d' | awk 'FNR>3 {print $2}'`
    do
        if [[ $i =~ [-]{1} ]]
        then
            MESSAGEID=${i#-}
            echo "deleteMessage $MESSAGEID" >> /tmp/$account.$$
        else
            echo "deleteConversation $i" >> /tmp/$account.$$
        fi
    done

    if [ -f /tmp/$account.$$ ] & [ -s /tmp/$account.$$ ] ; then
        COUNT=`wc -l /tmp/$account.$$ | awk '{print $1}'`
        echo "$account: deleting $COUNT emails"
        zmmailbox -z -m $account -A < /tmp/$account.$$ >> /tmp/process.log.$$;
    else
        echo "$account: no emails found"
    fi
    rm -f /tmp/$account.$$
done
