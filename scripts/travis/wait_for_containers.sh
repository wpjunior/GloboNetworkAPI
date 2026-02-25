#!/bin/bash

APP_PIDFILE=/var/run/netapi.pid
APP_READY=0
ODL_READY=0

# Check if SDN containers are running
docker inspect ovs1 >/dev/null 2>&1
SDN_AVAILABLE=$?

if [ "$SDN_AVAILABLE" -ne "0" ]; then
    echo "SDN containers not available, skipping ODL check"
    ODL_READY=1
fi

echo "Checking if containers are ready"

MAX_RETRY=30
SLEEP_TIME=5

for i in $(seq 1  ${MAX_RETRY}); do

    # -- ODL
    if [ "$ODL_READY" -eq "0" ]; then
        docker exec ovs1 sh -c "ovs-vsctl show" 2>/dev/null | grep "is_connected" >/dev/null
        if [ "$?" -eq "0" ]; then
            echo "ODL is ready";
            ODL_READY=1;
        fi
    fi

    # -- APP
    if [ "$APP_READY" -eq "0" ]; then
        docker exec netapi_app sh -c "ls $APP_PIDFILE" >/dev/null 2>&1
        if [ "$?" -eq "0" ]; then
            echo "App is ready";
            APP_READY=1;
        fi
    fi

    if [ "$ODL_READY" -eq "1" ] && [ "$APP_READY" -eq "1" ]; then
        break;
    fi

    # When maximum retries is achieved we exit with an error message
    if [ "$i" -eq "${MAX_RETRY}" ]; then
        echo "Max retry achieved"
        exit 1;
    fi

    sleep ${SLEEP_TIME}
    echo "Retrying ${i}.."
done

echo "Environment ready"
