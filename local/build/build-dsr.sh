#!/bin/bash

set -euo pipefail

# This is a demo script for the DSR-Pipeline-Server
# This script creates PDF output from markdown input


###############@##################################
#Edit the below file to reflect your information
##################################################

source "../DSRVariables.env"

####################################################
####################################################
####################################################
#DO NOT CHANGE ANYTHING BELOW THIS LINE
####################################################
####################################################
####################################################

############################################################################################
# Setup key variables that will be used by the create-stakeholder-output-server.sh script
############################################################################################

export MO_PATH="bash ../../vendor/git.knownelement.com/ExternalVendorCode/mo/mo"

export StakeholderOutputMarkdownInputFile="$1"

echo "Cleaning up from previous runs..."

rm $BUILDYAML_STAKEHOLDER_OUTPUT || true
rm $StakeholderOutputMarkdownOutputFile || true
rm $StakeholderOutputPDFOutputFile || true

echo "Combining markdown files into single input file for pandoc..."
cat $StakeholderOutputMarkdownInputFile > $StakeholderOutputMarkdownOutputFile

#Call the build stakeholder output microservice
echo "Calling the build stakeholder output microservice..."
bash ../../vendor/git.knownelement.com/reachableceo/DSR-Pipeline-Server/build/build-stakeholder-output-server.sh