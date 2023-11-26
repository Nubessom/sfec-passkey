#!/usr/bin/env bash

# Exit when any command fails
set -ex

# Set Default values
PIPELINE=false
DURATION=14
ALIAS=""
HUBUSER=""

usage()
{
    echo ""
    echo "Usage:"
    echo "      -a      alias [ -a CI-1234 ]"
    echo "      -d      scratch org duration, default 14 [ -d 7 ]"
    echo "      -v      dev hub username [ -v name@nubessom.com ]"
    echo "      -p      silent mode for pipeline [ -p ]"
    exit 2
}

while getopts pa:d:v: option; do
    case "${option}"
    in
	a) ALIAS="-a ${OPTARG}";;
	d) DURATION=${OPTARG};;
	v) HUBUSER="-v ${OPTARG}";;
    p) PIPELINE=true;;
    \? ) usage;;
    esac
done

# Skip sfdx update inside pipeline
if [[ "$PIPELINE" == false ]]; then
    sf update
fi

sf org create scratch -f config/project-scratch-def.json --set-default $ALIAS --duration-days $DURATION $HUBUSER
sf project deploy start 

sf community publish -n "FIDO Passkey"

# No need to open scrach org during pipeline execution
if [[ "$PIPELINE" == false  ]]; then
    sfdx org open
fi
