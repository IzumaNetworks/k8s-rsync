#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SELF="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$SELF/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done

MYDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

#SSH_PORT="${SSH_PORT:-55556}"

#WATCHDIRS="${WATCHDIRS:-.}"

# we dont want to preserve permissions
#RSYNC=${RSYNC:-/usr/local/bin/rsync}
#RSYNC_CMD="${RSYNC} -vrltD"

RSYNC_CMD="${MYDIR}/krsync.sh -vrltD"

readlinkf() {

	local TARGET_FILE=$1

	pushd $(dirname "$TARGET_FILE")
	local TARGET_FILE=$(basename "$TARGET_FILE")

	# Iterate down a (possible) chain of symlinks
	while [ -L "$TARGET_FILE" ]
	do
		TARGET_FILE=$(readlink "$TARGET_FILE")
		cd $(dirname "$TARGET_FILE")
		TARGET_FILE=$(basename "$TARGET_FILE")
	done

	# Compute the canonicalized name by finding the physical path 
	# for the directory we're in and appending the target file.
	local PHYS_DIR=$(pwd -P)
	RESULT=$PHYS_DIR/$TARGET_FILE
	#RESULT=$PHYS_DIR
#	return $RESULT
	popd
}

watchdir(){
    #	fswatch -o -r -L . | xargs  -n1 -I{} $1
    fswatch -r -L ${WATCHES} | while read path ;
    do
	echo " ---------------- "
	echo "saw change: $path"
	# figure out the base path which changed
	readlinkf $path
	actualp=$RESULT
	echo "RESULT=$actualp"
	for p in ${PAIRS}; do
		LOCAL=${p%:*}
		REMOTE=${p#*:}
		readlinkf $LOCAL
		thislocal=$RESULT
		echo "Checking $p ($thislocal) $LOCAL - $actualp"
		case $actualp/ in
			$thislocal/*)
				echo "$actualp is in $LOCAL"	
				[[  -z "$PRETEND" ]] && ${RSYNC_CMD} $thislocal/ $POD:$REMOTE  || echo "${RSYNC_CMD} $thislocal/ $POD:$REMOTE"
#				[[  -z "$PRETEND" ]] && ${RSYNC_CMD} -ae "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR -T -o Compression=no -x" $thisp $REMOTE  || echo "${RSYNC_CMD} -o UserKnownHostsFile=/dev/null -ae \"ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -q -T -o Compression=no -x\" $thisp $REMOTE" 
				#[[  -z "$PRETEND" ]] && ${RSYNC_CMD} $thisp $REMOTE  || echo "${RSYNC_CMD} -o UserKnownHostsFile=/dev/null -ae \"ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -q -T -o Compression=no -x\" $thisp $REMOTE" 				
				;;
			*) echo "no match." ;;
		esac
		# if [[ "${thisp/* = $actualp ]]; then
		# 	echo "$actualp is in $p"
		# fi
	done
#	[[  -z "$PRETEND" ]] && ${RSYNC_CMD} -ae "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR -T -o Compression=no -x" $WATCH $REMOTE  || echo "${RSYNC_CMD} -o UserKnownHostsFile=/dev/null -ae \"ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -q -T -o Compression=no -x\" $WATCH $REMOTE" 
    done	
}


if [ $# -lt 2 ]; then
	echo "Need args"
	echo "Usage: $0 pod /local/path:/remote/path [/nother/local:/another/remove]..."
	exit 2
fi

POD="$1"
shift
# REMOTE="$1"
# shift

PAIRS="$@"

WATCHES=""


echo "initial sync...."
for p in ${PAIRS}; do
	LOCAL=${p%:*}
	WATCHES="${WATCHES} $LOCAL"
	REMOTE=${p#*:}
	echo "LOCAL: $LOCAL REMOTE: $REMOTE"
	readlinkf $LOCAL
	thislocal=$RESULT
	echo "Checking $p ($thislocal) $LOCAL"
	[[  -z "$PRETEND" ]] && ${RSYNC_CMD} $thislocal/ $POD:$REMOTE  || echo "${RSYNC_CMD} $thislocal/ $POD:$REMOTE"
	# if [[ "${thisp/* = $actualp ]]; then
	# 	echo "$actualp is in $p"
	# fi
done


#[[  -z "$PRETEND" ]] && ${RSYNC_CMD} -ae "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR -T -o Compression=no -x" $WATCH $REMOTE  || echo "${RSYNC_CMD} -o UserKnownHostsFile=/dev/null -ae \"ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -q -T -o Compression=no -x\" $WATCH $REMOTE" 
echo "watching.... ${WATCHES}"
watchdir

		
