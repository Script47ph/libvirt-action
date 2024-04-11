#!/bin/bash
DRONE_SSH_URL="https://github.com/appleboy/drone-ssh/releases/download/v1.7.4/drone-ssh-1.7.4-linux-amd64"
DRONE_SSH_BIN="drone-ssh"
DRONE_SSH_ARG="--ssh-key '$INPUT_KEY' -H $INPUT_HOST -p $INPUT_PORT -u $INPUT_USERNAME"

get_drone() {
    curl -fL --retry 3 --keepalive-time 2 $DRONE_SSH_URL -o $DRONE_SSH_BIN
    chmod +x $DRONE_SSH_BIN
}
cd scripts
get_drone
sh -c ./$DRONE_SSH_BIN $DRONE_SSH_ARG --script pwd