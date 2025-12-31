#!/bin/bash
set -e

ORG=$1
KEY_FILE=$2

echo "ORG: $ORG" >&2
echo "Using service account key: $KEY_FILE" >&2

if [ ! -f "$KEY_FILE" ]; then
  echo "❌ Service account key file '$KEY_FILE' not found." >&2
  exit 1
fi

echo "🔑 Authenticating with service account..." >&2
gcloud auth activate-service-account --key-file="$KEY_FILE" >&2

access_token=$(gcloud auth print-access-token)

if [ -z "$access_token" ]; then
  echo "❌ Failed to obtain access token." >&2
  exit 1
fi

echo "✅ Access Token acquired." >&2

# ONLY print token to stdout
echo "$access_token"
