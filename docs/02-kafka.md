# Phase 2: Apache Kafka & the producer

## What and Why

**Kafka** is a distributed **event log** (often called a message queue). Producers append messages; consumers read at their own pace. Multiple consumers can read the same stream without blocking each other.

**Analogy:** A post office with **topics** = labeled mailboxes. Producers drop letters in; consumers pick them up. Each letter gets a serial number (**offset**) so you never lose your place. If the sentiment analyzer is slow, letters pile up in the box instead of crashing the news fetcher.

**Why for this project:** Fetching news (every 10 min) and analyzing sentiment (slower, can fail) should be **decoupled**. Kafka sits between them.

### Key concepts

| Term | Meaning |
|------|---------|
| **Broker** | Kafka server that stores messages |
| **Topic** | Named channel (e.g. `news-raw`) |
| **Producer** | Writes messages to a topic |
| **Consumer** | Reads messages from a topic |
| **Offset** | Position of a message in a partition (bookmark) |
| **Zookeeper** | Coordinates Kafka brokers (used in our Docker setup) |

---

## Task 1 ✅ — Verify Kafka is running

**Explanation:** Confirm the broker from Phase 1 accepts connections.

**Code/command:**

```bash
docker compose ps kafka
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list
```

**Expected result:** Command succeeds; list may be empty or show internal topics.

### Checkpoint

```bash
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092 | head -5
```

No connection errors.

---

## Task 2 ✅ — Create topic `news-raw`

**Explanation:** Topics are not always auto-created in production; we create explicitly to learn the CLI.

**Code/command:**

```bash
docker exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --create \
  --topic news-raw \
  --partitions 1 \
  --replication-factor 1

# Describe topic
docker exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --describe \
  --topic news-raw
```

**Expected result:** `Topic: news-raw` with partition 0, leader 1.

### Checkpoint

```bash
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | grep news-raw
```

Line `news-raw` appears.

---

## Task 3 ✅ — Send a test message manually

**Explanation:** Prove you can write to the topic before Python.

**Code/command:**

```bash
docker exec -it kafka kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic news-raw
```

Type one line of JSON and press Enter:

```json
{"title":"Test headline","source":"manual","publishedAt":"2026-05-24T12:00:00Z"}
```

Press `Ctrl+C` to exit.

**Expected result:** No error; message accepted.

### Checkpoint

(Skip to Task 4 — reading confirms send worked.)

---

## Task 4 ✅ — Read the message back

**Explanation:** Console consumer reads from beginning (`--from-beginning`).

**Code/command:**

```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic news-raw \
  --from-beginning \
  --max-messages 1
```

**Expected result:** Prints your JSON line, then exits (with `--max-messages 1`).

### Checkpoint

You see the exact JSON you typed in Task 3.

---

## Task 5 ✅ — Write producer.py

**Explanation:** Script fetches top headlines from NewsAPI and publishes each article as one Kafka message.

**Code/command:**

1. Create `requirements.txt` in repo root:

```text
requests==2.31.0
kafka-python==2.0.2
python-dotenv==1.0.0
```

2. Install locally:

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# Mac/Linux: source .venv/bin/activate
pip install -r requirements.txt
```

3. Create `producer/producer.py`:

```python
"""
producer.py — Fetch news from NewsAPI and publish to Kafka topic news-raw.
Run: python producer/producer.py
"""
import json
import os
import sys
from datetime import datetime, timezone

import requests
from dotenv import load_dotenv
from kafka import KafkaProducer

# Load NEWS_API_KEY and KAFKA_* from .env in repo root
load_dotenv()

NEWS_API_KEY = os.getenv("NEWS_API_KEY")
KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "news-raw")


def fetch_headlines() -> list[dict]:
    """Call NewsAPI top-headlines endpoint; return list of article dicts."""
    if not NEWS_API_KEY:
        raise ValueError("NEWS_API_KEY missing in .env")

    url = "https://newsapi.org/v2/top-headlines"
    params = {
        "country": "us",       # change to 'il' etc. if you prefer
        "pageSize": 20,        # max articles per run (save quota)
        "apiKey": NEWS_API_KEY,
    }
    response = requests.get(url, params=params, timeout=30)
    response.raise_for_status()
    data = response.json()
    if data.get("status") != "ok":
        raise RuntimeError(f"NewsAPI error: {data}")
    return data.get("articles", [])


def make_producer() -> KafkaProducer:
    """Create Kafka producer that serializes dicts to JSON bytes."""
    return KafkaProducer(
        bootstrap_servers=KAFKA_BOOTSTRAP.split(","),
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        key_serializer=lambda k: k.encode("utf-8") if k else None,
    )


def publish_articles(producer: KafkaProducer, articles: list[dict]) -> int:
    """Send each article to Kafka; return count published."""
    count = 0
    for article in articles:
        payload = {
            "title": article.get("title"),
            "description": article.get("description"),
            "url": article.get("url"),
            "source": (article.get("source") or {}).get("name"),
            "publishedAt": article.get("publishedAt"),
            "fetchedAt": datetime.now(timezone.utc).isoformat(),
        }
        # Use URL as key so same story updates same partition key
        key = article.get("url") or str(count)
        producer.send(KAFKA_TOPIC, key=key, value=payload)
        count += 1
    producer.flush()
    return count


def main() -> None:
    articles = fetch_headlines()
    print(f"Fetched {len(articles)} articles from NewsAPI")
    producer = make_producer()
    n = publish_articles(producer, articles)
    print(f"Published {n} messages to topic '{KAFKA_TOPIC}'")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
```

**Expected result:** File exists; imports resolve after `pip install`.

### Checkpoint

```bash
python -c "import kafka; import requests; print('ok')"
```

Prints `ok`.

---

## Task 6 ✅ — Test producer.py

**Explanation:** Run from host; messages should appear in Kafka.

**Code/command:**

```bash
# From repo root with venv activated
python producer/producer.py
```

**Expected result:** Console shows fetched count and published count (e.g. 20).

Verify in Kafka:

```bash
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic news-raw \
  --from-beginning \
  --max-messages 3 \
  --timeout-ms 5000
```

**Expected result:** JSON lines with `title`, `url`, `fetchedAt`, etc.

### Checkpoint

```bash
docker exec kafka kafka-run-class kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic news-raw --time -1
```

Shows non-zero offset for partition 0 after producer run.

---

## How this connects to the project

The producer is the **ingestion edge**: it turns an external API into a durable stream. Airflow (Phase 3) will run this script on a schedule instead of you typing the command. The consumer (Phase 4) will subscribe to the same `news-raw` topic.
