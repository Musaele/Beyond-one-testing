#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

echo "🔍 Ensuring local newman and htmlextra reporter are installed..."

if [ ! -d "node_modules/newman" ] || [ ! -d "node_modules/newman-reporter-htmlextra" ]; then
  echo "⚙️ Installing local dependencies..."
  npm install newman newman-reporter-htmlextra --save-dev
else
  echo "✅ Local dependencies already installed."
fi

# ---------------------------------------------------
# Step 1: Define variables
# ---------------------------------------------------
PROXY_DIR="$1"  # Example: test-call
COLLECTION_PATH="api-proxies/$PROXY_DIR/tests/integration"
TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"

# ---------------------------
# FIX: Construct correct Apigee Base URL
# ---------------------------
APIGEE_HOST="https://${ORG}-${APIGEE_ENVIRONMENT}.apigee.net"

# FIX: Read basepath from proxy bundle if exists
if [ -f "api-proxies/$PROXY_DIR/apiproxy/proxies/default.xml" ]; then
  BASEPATH=$(xmllint --xpath "string(//ProxyEndpoint/HTTPProxyConnection/BasePath)" \
    "api-proxies/$PROXY_DIR/apiproxy/proxies/default.xml")
else
  BASEPATH="/$PROXY_DIR"
fi

# Clean basepath
BASEPATH="${BASEPATH#/}"   # remove leading slash
BASEPATH="${BASEPATH%%/}"  # remove trailing slash

FINAL_URL="$APIGEE_HOST/$BASEPATH"

echo "🚀 Proxy        : $PROXY_DIR"
echo "🌍 APIGEE URL   : $FINAL_URL"
echo "📁 Tests folder : $COLLECTION_PATH"

if [ ! -d "$COLLECTION_PATH" ]; then
  echo "⚠️ No integration tests found in $COLLECTION_PATH, skipping."
  exit 0
fi


# ---------------------------------------------------
# Step 2: Run each test collection
# ---------------------------------------------------
find "$COLLECTION_PATH" -type f -name "*.json" | while read -r collection; do
  COLLECTION_NAME="$(basename "$collection" .json)"
  REPORT_DIR="reports/newman/$PROXY_DIR/${COLLECTION_NAME}_${TIMESTAMP}"

  echo "🧪 Running tests for: $COLLECTION_NAME"
  mkdir -p "$REPORT_DIR"

  npx newman run "$collection" \
    --env-var "url=$FINAL_URL" \
    --reporters cli,junit,htmlextra \
    --reporter-junit-export "$REPORT_DIR/junitReport.xml" \
    --reporter-htmlextra-export "$REPORT_DIR/index.html" \
    --reporter-htmlextra-title "$PROXY_DIR – $COLLECTION_NAME"

  echo "✅ Reports generated in: $REPORT_DIR"
done

echo "🎉 All integration tests completed successfully."