source ../DSRVariables.env

echo "Obtaining discourse api key..."
bw logout
bw config server "$BITWARDEN_SERVER_URL"
source "$BITWARDEN_CREDS"
bw login --apikey $BW_CLIENTID $BW_CLIENTSECRET
export BW_SESSION="$(bw unlock --passwordenv TSYS_BW_PASSWORD_REACHABLECEO --raw)"
export DISCOURSE_API_KEY="$(bw get password APIKEY-discourse)"

echo "Posting DSR..."

# The content of the post
CONTENT="Please use the link below to download today's stakeholder report."

# The file to upload (from the second argument or auto-generated based on date)
FILE_PATH="$StakeholderOutputPDFOutputFile"

# Check if the file exists
if [ ! -f "$FILE_PATH" ]; then
  echo "File not found: $FILE_PATH"
  exit 1
fi

# Upload the file
echo "Uploading file..."
upload_response=$(curl -s -X POST "$DISCOURSE_URL/uploads.json" \
  -H "Content-Type: multipart/form-data" \
  -H "Api-Key: $DISCOURSE_API_KEY" \
  -H "Api-Username: $DISCOURSE_API_USERNAME" \
  -F "file=@$FILE_PATH;type=application/pdf" \
  -F "type=composer")

echo "Upload Response: $upload_response"

# Extract the short_url from the response
short_url=$(echo "$upload_response" | /mingw64/bin/jq -r '.short_url')

# Check if the short_url was returned
if [ "$short_url" == "null" ]; then
  echo "Failed to extract short_url. Response:"
  echo "$upload_response"
  exit 1
fi

echo "File uploaded successfully. Short URL: $short_url"

# Append the file link to the post content (Markdown format)
CONTENT="$CONTENT\n\n[Download todays report in PDF format]($short_url)"

# Create the new topic
echo "Creating new topic..."
post_response=$(curl -s -X POST "$DISCOURSE_URL/posts.json" \
  -H "Content-Type: application/json" \
  -H "Api-Key: $DISCOURSE_API_KEY" \
  -H "Api-Username: $DISCOURSE_API_USERNAME" \
  -d @- <<EOF
{
  "title": "$DISCOURSE_POST_TITLE",
  "raw": "$CONTENT",
  "category": $DISCOURSE_CATEGORY_ID
}
EOF
)

echo "Post Response: $post_response"

# Check if the post creation was successful
if echo "$post_response" | grep -q '"id":'; then
  echo "Post created successfully!"
else
  echo "Failed to create post. Response:"
  echo "$post_response"
  exit 1
fi