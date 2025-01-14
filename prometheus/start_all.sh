#!/bin/bash

function start_all() {
    echo "Starting all services..."

}

function kill_all() {
    echo "Killing all services..."
}

if [ "$1" = "start" ]; then
    kill_all
    start_all
elif [ "$1" = "kill" ]; then
    kill_all
else
    echo "Usage: $0 start|kill"
    exit 1
fi
