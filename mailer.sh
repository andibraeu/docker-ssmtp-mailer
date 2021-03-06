#!/bin/sh

: ${TO:?Variable TO is required!}
: ${FROM_EMAIL:?Variable FROM_EMAIL is required!}
: ${SMTP_HOST:?Variable SMTP_HOST is required!}

: ${MESSAGE:-""}

if [ "${TLS}" == "" ]; then TLS=YES; fi;
if [ "${STARTTLS}" == "" ]; then STARTTLS=YES; fi;
if [ "${SUBJECT}" == "" ]; then SUBJECT="No Subject"; fi;
if [ "${FROM_NAME}" == "" ]; then FROM_NAME="${FROM_EMAIL}"; else FROM_NAME="=?utf-8?B?"$(echo "${FROM_NAME}" | base64)"?="; fi;

CONFIGFILE="/etc/ssmtp/ssmtp.conf"
cat > $CONFIGFILE << EOF
mailhub=${SMTP_HOST}
UseTLS=${TLS}
UseSTARTTLS=${STARTTLS}
EOF
[ -n "$SMTP_USER" ] && echo "AuthUser=${SMTP_USER}" >> $CONFIGFILE
[ -n "$SMTP_PASS" ] && echo "AuthPass=${SMTP_PASS}" >> $CONFIGFILE

usermod -c "${FROM_NAME}" root

cat > /etc/ssmtp/revaliases << EOF
root:${FROM_EMAIL}:${SMTP_HOST}
EOF

ENCODED_SUBJECT=$(echo "${SUBJECT}" | base64)

cat > /tmp/ssmtp.txt << EOF
Content-Type: text/plain; charset=utf-8
Subject: =?utf-8?B?${ENCODED_SUBJECT}?=

EOF
if [ -z "${MESSAGE}" ]; then
    while read input; do
        echo $input >> /tmp/ssmtp.txt
    done;
else
    IFS=$'\r\n';
    for i in ${MESSAGE}; do
        echo "${i}" >> /tmp/ssmtp.txt
    done;
fi;

cat /tmp/ssmtp.txt | ssmtp "${TO}"
