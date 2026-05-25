"""
producer.py — Fetch news from NewsAPI and publish to Kafka topic news-raw.
Run from repo root: python producer/producer.py
"""
from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import requests
from dotenv import load_dotenv
from kafka import KafkaProducer

_REPO_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(_REPO_ROOT / ".env")

NEWS_API_KEY = os.getenv("NEWS_API_KEY")
KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "news-raw")


def fetch_headlines() -> list[dict]:
    """Call NewsAPI top-headlines endpoint; return list of article dicts."""
    if not NEWS_API_KEY:
        raise ValueError("NEWS_API_KEY missing in .env")

    url = "https://newsapi.org/v2/top-headlines"
    params = {
        "country": "us",
        "pageSize": 20,
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
