# Phase 1: Docker & docker-compose

## What and Why

**Docker** packages an application plus everything it needs (Python version, libraries, config) into an **image**. When you run an image, you get a **container** — a lightweight, isolated process on your machine.

**Analogy:** Shipping containers. Before containers, every ship loaded cargo differently. With standard containers, any crane, truck, or ship handles the same box. Docker does that for software: "run this exact box" works on your laptop, your teammate's Mac, and a Linux server.

**docker-compose** is a YAML file that defines **many** containers and how they connect (networks, ports, volumes). One command starts your entire data stack.

**Why for this project:** Kafka, Elasticsearch, and Airflow are painful to install natively on Windows. Docker gives you a production-like stack in minutes.

---

## Task 1 ✅ — Install Docker Desktop

**Explanation:** Docker Desktop includes the Docker engine and Compose on Windows/Mac.

**Code/command:**

1. Download from https://www.docker.com/products/docker-desktop/
2. Install and restart if prompted.
3. Enable WSL 2 backend on Windows (installer usually guides you).

**Expected result:** Docker whale icon in system tray; engine running.

### Checkpoint

```bash
docker --version
docker compose version
docker run hello-world
```

You should see: `Hello from Docker!` and exit code 0.

---

## Task 2 ✅ — Run your first container

**Explanation:** `docker run` downloads an image (if missing) and starts a one-off container.

**Code/command:**

```bash
# Pull and run interactive Ubuntu shell (type 'exit' to leave)
docker run -it --rm ubuntu:22.04 bash -c "echo 'I am inside a container' && cat /etc/os-release | head -2"
```

**Expected result:** Prints greeting and Ubuntu version from **inside** the container, not your host OS.

### Checkpoint

```bash
docker ps -a --filter "ancestor=hello-world" --format "{{.Status}}"
```

Shows exited hello-world container (or empty if `--rm` was used).

---

## Task 3 ✅ — Understand docker-compose.yml structure

**Explanation:** Key building blocks you'll use in Task 4.

| Key | Meaning |
|-----|---------|
| `services:` | Each named service = one container (or scaled group) |
| `image:` | Which Docker image to use |
| `ports:` | `host:container` port mapping |
| `environment:` | Env vars inside container |
| `volumes:` | Persistent or mounted files |
| `depends_on:` | Start order (not health-aware) |
| `networks:` | Containers on same network resolve each other by **service name** |

**Code/command:** Open `news-pipeline/docker-compose.yml` (currently empty). Read this minimal example:

```yaml
# Example only — do not use as final file
services:
  myapp:
    image: nginx:alpine          # which image to pull
    ports:
      - "8888:80"                # localhost:8888 -> container port 80
    environment:
      - NGINX_HOST=localhost     # env var inside container
```

**Expected result:** You can explain what `8888:80` means without running it.

### Checkpoint

Answer aloud: "If Elasticsearch has `ports: - '9200:9200'`, what URL do I open in my browser?"  
**Answer:** http://localhost:9200

---

## Task 4 ✅ — Write the full docker-compose.yml

**Explanation:** This stack runs Zookeeper + Kafka (Kafka needs ZK in this setup), Elasticsearch, Kibana, and Airflow (webserver + scheduler + init). Airflow mounts your `dags/` folder.

**Code/command:** Replace the contents of `docker-compose.yml` with:

```yaml
# docker-compose.yml — full local stack for news pipeline
# Run from repo root: docker compose up -d

services:
  # --- Zookeeper (required by Kafka in this configuration) ---
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"

  # --- Kafka broker ---
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      # Listeners: internal (Docker network) + external (your laptop)
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:29092,PLAINTEXT_HOST://0.0.0.0:9092
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"

  # --- Elasticsearch (document store / search) ---
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - es_data:/usr/share/elasticsearch/data

  # --- Kibana (visualization UI) ---
  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    container_name: kibana
    depends_on:
      - elasticsearch
    ports:
      - "5601:5601"
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200

  # --- Airflow (metadata DB + init + scheduler + UI) ---
  postgres:
    image: postgres:15
    container_name: airflow-postgres
    environment:
      POSTGRES_USER: airflow
      POSTGRES_PASSWORD: airflow
      POSTGRES_DB: airflow
    volumes:
      - postgres_data:/var/lib/postgresql/data

  airflow-init:
    image: apache/airflow:2.8.0
    container_name: airflow-init
    depends_on:
      - postgres
    environment: &airflow-common-env
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres/airflow
      AIRFLOW__CORE__FERNET_KEY: ''
      AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION: 'true'
      AIRFLOW__CORE__LOAD_EXAMPLES: 'false'
      AIRFLOW__API__AUTH_BACKENDS: airflow.api.auth.backend.basic_auth
      _AIRFLOW_DB_MIGRATE: 'true'
      _AIRFLOW_WWW_USER_CREATE: 'true'
      _AIRFLOW_WWW_USER_USERNAME: admin
      _AIRFLOW_WWW_USER_PASSWORD: admin
    volumes:
      - ./dags:/opt/airflow/dags
      - ./producer:/opt/airflow/producer
      - ./logs:/opt/airflow/logs
    entrypoint: /bin/bash
    command:
      - -c
      - |
        airflow db migrate
        airflow users create --username admin --password admin --firstname Admin --lastname User --role Admin --email admin@example.com || true

  airflow-webserver:
    image: apache/airflow:2.8.0
    container_name: airflow-webserver
    depends_on:
      - airflow-init
      - postgres
    ports:
      - "8080:8080"
    environment:
      <<: *airflow-common-env
    volumes:
      - ./dags:/opt/airflow/dags
      - ./producer:/opt/airflow/producer
      - ./logs:/opt/airflow/logs
    command: webserver
    healthcheck:
      test: ["CMD", "curl", "--fail", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 5

  airflow-scheduler:
    image: apache/airflow:2.8.0
    container_name: airflow-scheduler
    depends_on:
      - airflow-init
      - postgres
    environment:
      <<: *airflow-common-env
    volumes:
      - ./dags:/opt/airflow/dags
      - ./producer:/opt/airflow/producer
      - ./logs:/opt/airflow/logs
    command: scheduler

volumes:
  es_data:
  postgres_data:
```

Create empty logs folder:

```bash
mkdir -p logs
```

**Expected result:** Single file defines entire infrastructure; paths `./dags` and `./producer` mount into Airflow.

### Checkpoint

```bash
docker compose config
```

Prints merged YAML with no syntax errors.

---

## Task 5 ✅ — Run docker-compose up and verify health

**Explanation:** First start downloads images (several GB). Be patient.

**Code/command:**

```bash
cd news-pipeline
docker compose up -d
```

Watch startup:

```bash
docker compose ps
```

**Expected result:** Services show `running`; Airflow may show `healthy` after ~1–2 min.

### Checkpoint

```bash
# Elasticsearch
curl http://localhost:9200
# Expect JSON with "cluster_name" and "tagline"

# Kibana (wait 60–90s after up)
curl -I http://localhost:5601
# Expect HTTP/1.1 302 or 200

# Kafka broker API versions (from inside network)
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092

# Airflow UI — browser
# http://localhost:8080  user: admin  password: admin
```

---

## Common errors and fixes

| Error | Fix |
|-------|-----|
| Port already in use | Change left side of `ports:` or stop conflicting app — see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) |
| ES won't start (memory) | Increase Docker RAM; run `vm.max_map_count` fix on WSL |
| Airflow init loops | `docker compose logs airflow-init` — delete volumes: `docker compose down -v` (destructive) |
| Kafka connection from host fails | Check `KAFKA_ADVERTISED_LISTENERS` includes `localhost:9092` |

---

## How this connects to the project

Docker is the **foundation layer**. Every other phase assumes these containers are running: Kafka for messages, Airflow for schedule, Elasticsearch + Kibana for storage and charts. Without Task 5 green, stop and fix before opening `02-kafka.md`.
