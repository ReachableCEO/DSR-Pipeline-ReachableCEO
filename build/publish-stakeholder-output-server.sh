#!/bin/bash

echo "Posting Stakeholder Report..."

# Check if the file exists
if [ ! -f "$FILE_PATH" ]; then
  echo "File not found: $FILE_PATH"
  exit 1
fi

# Upload the file
echo "Uploading file..."
upload_response=$(curl -s -X POST "$DISCOURSE_URL/uploads.json" \
  -H "Content-Type: multipart/form-data" \
  -H "Api-Key: $API_KEY" \
  -H "Api-Username: $API_USERNAME" \
  -F "file=@$FILE_PATH;type=application/pdf" \
  -F "type=composer")

echo "Upload Response: $upload_response"

# Extract the short_url from the response
short_url=$(echo "$upload_response" | jq -r '.short_url')

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
  -H "Api-Key: $API_KEY" \
  -H "Api-Username: $API_USERNAME" \
  -d @- <<EOF
{
  "title": "$TITLE",
  "raw": "$CONTENT",
  "category": $CATEGORY_ID
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