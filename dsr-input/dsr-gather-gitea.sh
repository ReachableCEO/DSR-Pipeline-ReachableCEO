#!/bin/bash

# Script to query Gitea API for a user's activity on a specific date

########################################################################################################
#Obtain gitea api key from bitwarden
########################################################################################################

####################################
## Step 0: Set to use tsys server
####################################
bw logout

echo "Setting cli to use tsys bitwarden server..."
bw config server https://pwvault.turnsys.com

####################################
## Step 1: login to bitwarden
####################################

# From: https://bitwarden.com/help/cli/#using-an-api-key

### Set apikey environment varaible

echo "Sourcing clientid/apikey data..."
source D:/tsys/secrets/bitwarden/data/apikey-bitwarden-reachableceo

### Login to vault using apikey...

echo "Logging in..."
bw login --apikey $BW_CLIENTID $BW_CLIENTSECRET

### Step 1.1: unlock / save session id 

echo "Unlocking..."
export BW_SESSION="$(bw unlock --passwordenv TSYS_BW_PASSWORD_REACHABLECEO --raw)"


### Step 2: retrive a value into an environment variable

export GITEA_APIKEY="$(bw get password APIKEY-Gitea)"

########################################################################################################
# Accrss gitea data
########################################################################################################

# Script to query Gitea API for a user's activity on a specific date

# Usage: ./get_gitea_user_activity.sh <username> <date> [GITEA_URL] [TOKEN]

# Set username, date, and default Gitea URL
USERNAME="${1:-reachableceo}"                    # Default to "reachableceo" if not provided
DATE="${2:-$(date +%Y-%m-%d)}"                   # Default to today's date if not provided
GITEA_URL="${3:-https://git.knownelement.com}"   # Default Gitea URL if not provided
TOKEN="${GITEA_APIKEY}"                      # Use APIKEY-GItea or passed argument

# API Endpoint for user activities
API_ENDPOINT="$GITEA_URL/api/v1/users/$USERNAME/timeline"

# Make the API call
if [ -n "$TOKEN" ]; then
  # If token is provided, use it in the Authorization header
  RESPONSE=$(curl -s -H "Authorization: token $TOKEN" "$API_ENDPOINT")
else
  # If no token is provided, make an unauthenticated request
  RESPONSE=$(curl -s "$API_ENDPOINT")
fi

# Check for API errors
if [[ "$RESPONSE" == "Not found" || -z "$RESPONSE" ]]; then
  echo "Error: User '$USERNAME' not found, or endpoint is incorrect."
  exit 1
fi

# Validate JSON response
if ! echo "$RESPONSE" | jq empty >/dev/null 2>&1; then
  echo "Error: Invalid JSON response from Gitea API."
  echo "Response: $RESPONSE"
  exit 1
fi

# Filter the activity by date using jq
echo "$RESPONSE" | jq --arg date "$DATE" '[.[] | select(.created_at | startswith($date))]'