#!/bin/bash
DRONE_SSH_BIN="drone-ssh"
DRONE_SSH_ARG="--ssh-key '$INPUT_KEY' -H $INPUT_HOST -p $INPUT_PORT -u $INPUT_USERNAME --script"
cd scripts
sh -c ./$DRONE_SSH_BIN $DRONE_SSH_ARG ./installer.sh