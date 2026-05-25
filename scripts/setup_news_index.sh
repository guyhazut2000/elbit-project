#!/usr/bin/env bash
# setup_news_index.sh — create Elasticsearch index "news" with mapping
set -euo pipefail

ES_URL="${ELASTICSEARCH_URL:-http://localhost:9200}"

echo "Creating index 'news' at ${ES_URL} ..."
curl -sf -X PUT "${ES_URL}/news" -H "Content-Type: application/json" -d '{
  "mappings": {
    "properties": {
      "title": { "type": "text" },
      "description": { "type": "text" },
      "url": { "type": "keyword" },
      "source": { "type": "keyword" },
      "publishedAt": { "type": "date" },
      "fetchedAt": { "type": "date" },
      "sentiment": { "type": "keyword" },
      "sentiment_score": { "type": "float" }
    }
  }
}' | head -c 200
echo ""
echo "Done. Verify: curl ${ES_URL}/news/_mapping?pretty"
