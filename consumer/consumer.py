"""
consumer.py — Read news from Kafka, analyze sentiment, index to Elasticsearch.
Run from repo root: python consumer/consumer.py
Leave running while the pipeline is active.
"""
from __future__ import annotations

import json
import os
import signal
import sys
from pathlib import Path

from dotenv import load_dotenv
from elasticsearch import Elasticsearch
from kafka import KafkaConsumer
from textblob import TextBlob

_REPO_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(_REPO_ROOT / ".env")

KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "news-raw")
ES_URL = os.getenv("ELASTICSEARCH_URL", "http://localhost:9200")
ES_INDEX = os.getenv("ELASTICSEARCH_INDEX", "news")

running = True


def shutdown_handler(signum, frame) -> None:
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

    print(f"Listening on topic '{KAFKA_TOPIC}' -> index '{ES_INDEX}'")

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

        doc_id = doc.get("url") or None
        es.index(index=ES_INDEX, id=doc_id, document=enriched)
        print(f"Indexed: {title[:60]!r} -> {label} ({score:.2f})")

    consumer.close()
    print("Consumer stopped.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
