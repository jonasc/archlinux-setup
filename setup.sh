#!/usr/bin/bash

run() {
    if ! "$@"
    then
        code=$!
        echo "$(tput bold; tput setaf 5)The following command executed with error $code:"
        echo "$@"
        exit $code
    fi
}

# Load german keyboard layout
run loadkeys de-latin1
