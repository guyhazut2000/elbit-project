# Kibana — News Intelligence dashboard

After `consumer/consumer.py` has indexed documents into the `news` index:

1. Open http://localhost:5601
2. **Stack Management** → **Data views** → Create data view `news`, time field `fetchedAt`
3. Create visualizations (see `docs/04-elasticsearch.md` Task 5):
   - **Articles per hour** — date histogram on `fetchedAt`, metric count
   - **Sentiment distribution** — pie, terms on `sentiment`
   - **Latest articles** — table: `title`, `source`, `sentiment`, `publishedAt`, limit 10
4. **Dashboard** → add all three → save as **News Intelligence**

Re-run `python producer/producer.py` while the consumer is running to see the dashboard update.
