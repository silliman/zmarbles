#!/bin/bash

function killMarblesAndParentGulp() {
  PORT=${1}
  MARBLES=`lsof -i tcp:${PORT} -t`

  if [ "${MARBLES}" = "" ] ; then
    echo "No process found listening on port ${PORT}"
  else
    MARBLES_PARENT=`ps -o ppid= ${MARBLES}`
    IS_GULP=`ps -f ${MARBLES_PARENT} | grep gulp`
    if [ "${IS_GULP}" = "" ]; then
       echo 'parent process was not gulp- it will not be killed'
    else
       echo "Killing gulp process with pid ${MARBLES_PARENT}"
       kill -9 ${MARBLES_PARENT}
    fi
    echo "Killing marbles process ${MARBLES} listening on port ${PORT}"
    kill -9 ${MARBLES}
  fi
}

killMarblesAndParentGulp 3001
killMarblesAndParentGulp 3002
