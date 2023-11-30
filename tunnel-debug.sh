#!/bin/bash

# the base port we start with
SSH_PORT="${SSH_PORT:-55556}"

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SELF="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$SELF/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done

MYDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

if [ ! -e "/etc/os-release" ]; then
    echo "Cant find /etc/os-release - assume Ubuntu?"
    ID="ubuntu"
else
    source /etc/os-release
fi

while getopts "o:" arg; do
    case $arg in
        o)
         offset=$OPTARG
         re='^[0-9]+$'
         if ! [[ $offset =~ $re ]] ; then
            echo "  error: Not a number ($OPTARG)" >&2; exit 1
         fi         
         echo "offset: $offset"
         SSH_PORT=$(($SSH_PORT+$offset))
         echo "SSH port now: $SSH_PORT"
    esac
done

case "$ID" in 
    alpine)
        if [ ! -e /etc/ssh/sshd_config ]; then
            # openrc needed for sshd init script
            #apk add openrc
            apk add openssh
            ssh-keygen -A
            echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
            echo "Starting sshd"
            /usr/sbin/sshd
        fi

        if [ ! -e "/usr/bin/rsync" ]; then
            apk add rsync
        fi
        ;;

    ubuntu)
        if [ ! -e /etc/ssh/sshd_config ]; then
            apt-get update
            apt-get install -y ssh
            echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
            /etc/init.d/ssh restart
        fi


        if ! command -v rsync &> /dev/null
        then
            apt-get update
            apt-get install -y rsync
        fi
        ;;
esac


if [ ! -e ${MYDIR}/tlaloc.key ]; then
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh 

if [[ ! -e ~/.tunnel-key-installed ]]; then

cat << EOF > /root/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmQtebE3yOHX+xzS2RHcUIh/hwzCq8OgjoI5EVSgJ6L thomashemphill@Thomass-Mac-Pro.localdomain
EOF

chmod 600 /root/.ssh/authorized_keys

cat << EOF > ${MYDIR}/tlaloc.key
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACA8DoPTXg0kttri6dR24rO0R+iwiWg5wjlPRLHsKCLcAgAAALCmo6nipqOp
4gAAAAtzc2gtZWQyNTUxOQAAACA8DoPTXg0kttri6dR24rO0R+iwiWg5wjlPRLHsKCLcAg
AAAEBBwPWqcYnJgvxdIDNN6ZZ1q5bMpBDAjZ1ZmDvGFnOlNTwOg9NeDSS22uLp1Hbis7RH
6LCJaDnCOU9EsewoItwCAAAAKnRob21hc2hlbXBoaWxsQFRob21hc3MtTWFjLVByby5sb2
NhbGRvbWFpbgECAw==
-----END OPENSSH PRIVATE KEY-----
EOF
chmod 600 ${MYDIR}/tlaloc.key
    fi

    touch ~/.tunnel-key-installed
fi

ssh -p 202 -R ${SSH_PORT}:localhost:22 -i ${MYDIR}/tlaloc.key container@net.tlaloc.us
