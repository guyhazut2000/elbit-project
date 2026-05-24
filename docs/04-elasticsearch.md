# Phase 4: Elasticsearch, consumer & Kibana

## What and Why

**Elasticsearch** is a distributed search and analytics engine. You store **documents** (JSON) in **indices** (like tables). It excels at full-text search, filters, and aggregations (counts, histograms).

**Analogy:** Google search for **your** data. You own the index; you decide the schema (**mapping**). Need "all negative headlines in the last hour"? Elasticsearch answers in milliseconds.

**Kibana** is the official UI on top of Elasticsearch — charts, tables, and discovery without writing a React dashboard.

**Why for this project:** Kafka messages are transient unless consumed. Elasticsearch is the **system of record** for headlines and sentiment scores that Kibana visualizes.

### Key concepts

| Term | Meaning |
|------|---------|
| **Index** | Collection of documents (e.g. `news`) |
| **Document** | One JSON record with `_id` |
| **Mapping** | Field types (text, keyword, date) |
| **Query / Aggregation** | Search and analytics DSL |

---

## Task 1 ✅ — Verify Elasticsearch is running

**Explanation:** Cluster health before creating indices.

**Code/command:**

```bash
curl http://localhost:9200
curl "http://localhost:9200/_cluster/health?pretty"
```

**Expected result:** `"status" : "green"` or `"yellow"` (yellow is OK for single-node).

### Checkpoint

```bash
curl http://localhost:9200/_cat/indices?v
```

Returns table header (indices may be empty).

---

## Task 2 ✅ — Create index `news`

**Explanation:** Define mapping so `publishedAt` is a date and `sentiment` is keyword for pie charts.

**Code/command:**

```bash
curl -X PUT "http://localhost:9200/news" -H "Content-Type: application/json" -d '{
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
}'
```

**Expected result:** `"acknowledged": true`

### Checkpoint

```bash
curl http://localhost:9200/news/_mapping?pretty
```

Shows `properties` for title, sentiment, etc.

---

## Task 3 ✅ — Insert a test document

**Explanation:** Manual index before the consumer exists.

**Code/command:**

```bash
curl -X POST "http://localhost:9200/news/_doc" -H "Content-Type: application/json" -d '{
  "title": "Manual test article",
  "description": "Learning Elasticsearch",
  "url": "https://example.com/test",
  "source": "manual",
  "publishedAt": "2026-05-24T10:00:00Z",
  "fetchedAt": "2026-05-24T10:05:00Z",
  "sentiment": "neutral",
  "sentiment_score": 0.0
}'
```

**Expected result:** JSON with `"result": "created"` and `"_id"`.

### Checkpoint

```bash
curl "http://localhost:9200/news/_search?pretty" -H "Content-Type: application/json" -d '{"query":{"match_all":{}}}'
```

Hits include your test document.

---

## Task 4 ✅ — Write consumer.py

**Explanation:** Read Kafka messages, compute simple sentiment, index into Elasticsearch.

**Code/command:**

Add to `requirements.txt`:

```text
elasticsearch==8.11.0
textblob==0.18.0.post0
```

Install:

```bash
pip install -r requirements.txt
```

Create `consumer/consumer.py`:

```python
"""
consumer.py — Read news from Kafka, analyze sentiment, index to Elasticsearch.
Run: python consumer/consumer.py
Leave running while pipeline is active.
"""
import json
import os
import signal
import sys

from dotenv import load_dotenv
from elasticsearch import Elasticsearch
from kafka import KafkaConsumer
from textblob import TextBlob

load_dotenv()

KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "news-raw")
ES_URL = os.getenv("ELASTICSEARCH_URL", "http://localhost:9200")
ES_INDEX = os.getenv("ELASTICSEARCH_INDEX", "news")

# Graceful shutdown flag
running = True


def shutdown_handler(signum, frame):
  global running
  print("\nShutting down consumer...")
  running = False


signal.signal(signal.SIGINT, shutdown_handler)
signal.signal(signal.SIGTERM, shutdown_handler)


def sentiment_label(text: str) -> tuple[str, float]:
    """Return (label, polarity) using TextBlob polarity in [-1, 1]."""
    if not text:
        return "neutral", 0.0
    polarity = TextBlob(text).sentiment.polarity
    if polarity > 0.1:
        return "positive", polarity
    if polarity < -0.1:
        return "negative", polarity
    return "neutral", polarity


def main() -> None:
    es = Elasticsearch(ES_URL)
    if not es.ping():
        raise RuntimeError(f"Cannot reach Elasticsearch at {ES_URL}")

    consumer = KafkaConsumer(
        KAFKA_TOPIC,
        bootstrap_servers=KAFKA_BOOTSTRAP.split(","),
        auto_offset_reset="earliest",
        enable_auto_commit=True,
        group_id="news-consumer-group",
        value_deserializer=lambda m: json.loads(m.decode("utf-8")),
    )

    print(f"Listening on topic '{KAFKA_TOPIC}' → index '{ES_INDEX}'")

    for message in consumer:
        if not running:
            break
        doc = message.value
        title = doc.get("title") or ""
        description = doc.get("description") or ""
        combined = f"{title}. {description}"
        label, score = sentiment_label(combined)

        enriched = {
            **doc,
            "sentiment": label,
            "sentiment_score": score,
        }

        # Index document; use URL as id for idempotency
        doc_id = doc.get("url") or None
        es.index(index=ES_INDEX, id=doc_id, document=enriched)
        print(f"Indexed: {title[:60]!r} → {label} ({score:.2f})")

    consumer.close()
    print("Consumer stopped.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
```

**Run consumer** (separate terminal, venv active):

```bash
python consumer/consumer.py
```

In another terminal, run producer once:

```bash
python producer/producer.py
```

**Expected result:** Consumer prints indexed lines; ES search returns articles with sentiment.

### Checkpoint

```bash
curl "http://localhost:9200/news/_count?pretty"
```

`count` increases after producer + consumer runs.

---

## Task 5 ✅ — Build a Kibana dashboard

**Explanation:** Connect Kibana to ES, create index pattern, build visualizations.

**Code/command:**

### Step 5a — Open Kibana

1. Browser: http://localhost:5601
2. Wait for Kibana to finish setup (first start can take 1–2 min)

### Step 5b — Create index pattern

1. **Management** → **Stack Management** → **Index Patterns** (or **Data Views** in newer UIs)
2. Create data view / index pattern: `news`
3. Time field: `publishedAt` or `fetchedAt`

### Step 5c — Bar chart: articles per hour

1. **Analytics** → **Visualize Library** → **Create visualization**
2. Type: **Vertical bar** (or Lens)
3. Index: `news`
4. Horizontal axis: **Date histogram** on `fetchedAt` (interval: 1 hour)
5. Vertical axis: **Count**
6. Save as `Articles per hour`

### Step 5d — Pie chart: sentiment distribution

1. New visualization → **Pie**
2. Slice by: **Terms** on field `sentiment.keyword` or `sentiment` (pick keyword type)
3. Size: 5
4. Save as `Sentiment distribution`

### Step 5e — Data table: latest 10 articles

1. New visualization → **Data table**
2. Rows: **Top hits** or table with columns `title`, `source`, `sentiment`, `publishedAt`
3. Sort by `fetchedAt` descending
4. Limit 10
5. Save as `Latest articles`

### Step 5f — Dashboard

1. **Dashboard** → **Create dashboard**
2. Add all three visualizations
3. Save as `News Intelligence`

**Expected result:** Dashboard updates when new data is indexed.

### Checkpoint

- Pie chart shows positive / negative / neutral slices after ≥10 documents
- Bar chart shows buckets when data spans multiple hours (or use `fetchedAt` with several producer runs)
- Table lists recent headlines

---

## How this connects to the project

Elasticsearch + Kibana are the **serving layer**: where stakeholders see trends. The consumer is the **processing layer** that turns raw Kafka JSON into enriched, searchable documents. Together they complete the architecture from the overview diagram.
