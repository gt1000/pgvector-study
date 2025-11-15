# 설치 (Installation)

docker를 이용한 설치 방법
- [Docker Compose를 이용한 신규 설치](#docker-compose를-이용한-신규-설치)
- [기 운영 PostgreSQL + PostGIS 환경에 pgvector 추가](#기존-postgresql--postgis-환경에-pgvector-추가)

---

## 1. Docker Compose를 이용한 신규 설치

### 보안 고려사항

⚠️ **기본 설정 사용 금지**
- 기본 사용자(`postgres`), 기본 DB(`postgres`) 사용하지 않음
- 강력한 비밀번호 사용
- 스키마 분리로 데이터 격리
- Connection Pooling 효율성을 위해 단일 DB 사용

### 1. 디렉토리 구조

```
project/
├── docker-compose.yml
├── .env
└── init-scripts/
    ├── 01-create-user-db.sql
    └── 02-init-pgvector.sql
```

### 2. 환경변수 파일 (.env)

```bash
# PostgreSQL 기본 설정 (보안 강화)
POSTGRES_USER=myapp_admin
POSTGRES_PASSWORD=YourSecurePassword123!@#
POSTGRES_DB=myapp_db

# Connection Pool 설정
MAX_CONNECTIONS=200

# 성능 최적화 설정
# 시스템 메모리에 맞게 조정 (예: 32GB 시스템 기준)
SHARED_BUFFERS=8GB
EFFECTIVE_CACHE_SIZE=16GB
MAINTENANCE_WORK_MEM=2GB
WORK_MEM=128MB

# CPU 설정 (시스템 코어 수에 맞게 조정)
MAX_PARALLEL_WORKERS=8
MAX_PARALLEL_WORKERS_PER_GATHER=4
MAX_PARALLEL_MAINTENANCE_WORKERS=4
MAX_WORKER_PROCESSES=16
```

### 3. docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: pgvector/pgvector:pg16
    container_name: pgvector-db
    restart: unless-stopped
    
    # 환경변수 파일 사용
    env_file:
      - .env
    
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    
    ports:
      - "5432:5432"
    
    volumes:
      # 데이터 영구 저장
      - pgvector_data:/var/lib/postgresql/data
      # 초기화 스크립트
      - ./init-scripts:/docker-entrypoint-initdb.d
    
    # 리소스 제한 해제 (로컬 환경 최대 활용)
    deploy:
      resources:
        limits:
          cpus: '16.0'     # 시스템의 모든 CPU 코어 사용
          memory: 32G      # 시스템 메모리에 맞게 조정
        reservations:
          cpus: '8.0'
          memory: 16G
    
    # PostgreSQL 성능 최적화 설정
    command: >
      postgres
      -c shared_buffers=${SHARED_BUFFERS:-8GB}
      -c effective_cache_size=${EFFECTIVE_CACHE_SIZE:-16GB}
      -c maintenance_work_mem=${MAINTENANCE_WORK_MEM:-2GB}
      -c work_mem=${WORK_MEM:-128MB}
      -c max_connections=${MAX_CONNECTIONS:-200}
      -c max_parallel_workers=${MAX_PARALLEL_WORKERS:-8}
      -c max_parallel_workers_per_gather=${MAX_PARALLEL_WORKERS_PER_GATHER:-4}
      -c max_parallel_maintenance_workers=${MAX_PARALLEL_MAINTENANCE_WORKERS:-4}
      -c max_worker_processes=${MAX_WORKER_PROCESSES:-16}
      -c random_page_cost=1.1
      -c effective_io_concurrency=200
      -c wal_buffers=16MB
      -c default_statistics_target=100
      -c checkpoint_completion_target=0.9
      -c max_wal_size=4GB
      -c min_wal_size=1GB
      -c wal_compression=on
      -c shared_preload_libraries='pg_stat_statements'
      -c pg_stat_statements.track=all
    
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pgvector_data:
    driver: local
```

### 4. 초기화 스크립트

#### `init-scripts/01-create-user-db.sql`

```sql
-- 보안: 기본 postgres 데이터베이스 접근 제한
REVOKE ALL ON DATABASE postgres FROM PUBLIC;

-- 모니터링용 extension 설치
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 기본 DB에 대한 정보 출력
SELECT 
    current_database() as database_name,
    current_user as current_user,
    version() as postgresql_version;
```

#### `init-scripts/02-init-pgvector.sql`

```sql
-- pgvector 전용 스키마 생성
CREATE SCHEMA IF NOT EXISTS vector_data;

-- pgvector extension을 vector_data 스키마에 설치
CREATE EXTENSION IF NOT EXISTS vector SCHEMA vector_data;

-- 기본 search_path 설정
ALTER DATABASE :DBNAME SET search_path TO public, vector_data;

-- pgvector 설치 확인
SELECT 
    extname,
    extversion,
    nspname as schema_name
FROM pg_extension e
JOIN pg_namespace n ON e.extnamespace = n.oid
WHERE extname = 'vector';

-- 예제 테이블 생성 (vector_data 스키마에)
CREATE TABLE IF NOT EXISTS vector_data.embeddings (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 스키마 정보 출력
\echo '=== Schemas ==='
\dn

-- 테이블 정보 출력
\echo '=== Tables in vector_data schema ==='
\dt vector_data.*

\echo 'pgvector installation completed successfully!'
```

### 5. 실행 및 확인

```bash
# 1. .env 파일 권한 설정 (보안)
chmod 600 .env

# 2. .gitignore에 .env 추가
echo ".env" >> .gitignore

# 3. 컨테이너 시작
docker-compose up -d

# 4. 로그 확인
docker-compose logs -f postgres

# 5. 헬스체크 확인
docker-compose ps

# 6. DB 접속 테스트
docker-compose exec postgres psql -U myapp_admin -d myapp_db

# 7. pgvector 설치 확인
docker-compose exec postgres psql -U myapp_admin -d myapp_db -c "
SELECT extname, extversion, nspname 
FROM pg_extension e 
JOIN pg_namespace n ON e.extnamespace = n.oid 
WHERE extname = 'vector';
"

# 8. 스키마 확인
docker-compose exec postgres psql -U myapp_admin -d myapp_db -c "\dn"

# 9. 테이블 확인
docker-compose exec postgres psql -U myapp_admin -d myapp_db -c "\dt vector_data.*"
```

### 6. 애플리케이션 연결 설정

#### Python 예제

```python
import psycopg2
from pgvector.psycopg2 import register_vector

# 연결 설정
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="myapp_db",
    user="myapp_admin",
    password="YourSecurePassword123!@#",
    options="-c search_path=vector_data,public"  # 스키마 설정
)

register_vector(conn)

# 사용 예제
cur = conn.cursor()

# vector_data 스키마의 테이블 사용
cur.execute("""
    INSERT INTO vector_data.embeddings (content, embedding)
    VALUES (%s, %s)
""", ("Sample text", [0.1] * 1536))

conn.commit()
```

#### Node.js 예제

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'myapp_db',
  user: 'myapp_admin',
  password: 'YourSecurePassword123!@#',
  // 스키마 설정
  options: '-c search_path=vector_data,public'
});

// 사용 예제
async function insertEmbedding() {
  const client = await pool.connect();
  try {
    await client.query(
      'INSERT INTO vector_data.embeddings (content, embedding) VALUES ($1, $2)',
      ['Sample text', '[0.1, 0.2, 0.3]']
    );
  } finally {
    client.release();
  }
}
```

### 7. 보안 체크리스트

- [ ] `.env` 파일을 `.gitignore`에 추가
- [ ] 강력한 비밀번호 사용 (최소 16자, 특수문자 포함)
- [ ] 기본 postgres 사용자/DB 사용 안 함
- [ ] 방화벽 설정으로 5432 포트 제한
- [ ] SSL/TLS 연결 사용 (프로덕션)
- [ ] 정기적인 비밀번호 변경

---

## 기존 PostgreSQL + PostGIS 환경에 pgvector 추가

이미 PostgreSQL + PostGIS가 docker-compose로 실행 중인 환경에 pgvector extension을 추가합니다.

### 상황 분석

**기존 환경:**
- PostgreSQL + PostGIS 컨테이너 실행 중
- 데이터베이스: `myapp_db`
- 기존 스키마: `public` (PostGIS 사용 중)

**목표:**
- 같은 DB 사용 (Connection Pooling 효율성)
- pgvector는 `vector_data` 스키마로 분리
- 기존 PostGIS 영향 없이 설치

### 1. 현재 상태 확인

```bash
# 현재 사용 중인 이미지 확인
docker-compose ps

# PostgreSQL 버전 확인
docker-compose exec postgres psql -U myapp_admin -d myapp_db -c "SELECT version();"

# 기존 extension 확인
docker-compose exec postgres psql -U myapp_admin -d myapp_db -c "\dx"
```

### 2. PostGIS + pgvector 커스텀 이미지 생성

`docker/Dockerfile.postgres` 생성:

```dockerfile
FROM postgres:16

# PostGIS 설치
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    postgresql-16-postgis-3 \
    postgresql-16-postgis-3-scripts && \
    rm -rf /var/lib/apt/lists/*

# pgvector 빌드 및 설치
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    postgresql-server-dev-16 && \
    cd /tmp && \
    git clone --branch v0.8.1 https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/pgvector && \
    apt-get remove -y build-essential git postgresql-server-dev-16 && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# 헬스체크
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}
```

### 3. docker-compose.yml 수정

**기존:**
```yaml
services:
  postgres:
    image: postgis/postgis:16-3.4
    # ... 기타 설정
```

**수정 후:**
```yaml
version: '3.8'

services:
  postgres:
    # 커스텀 이미지 사용
    build:
      context: ./docker
      dockerfile: Dockerfile.postgres
    container_name: postgres-postgis-pgvector
    restart: unless-stopped
    
    env_file:
      - .env
    
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    
    ports:
      - "5432:5432"
    
    volumes:
      # 기존 데이터 유지
      - postgres_data:/var/lib/postgresql/data
      # 초기화 스크립트 (새 extension 추가용)
      - ./migration-scripts:/docker-entrypoint-initdb.d
    
    deploy:
      resources:
        limits:
          cpus: '16.0'
          memory: 32G
        reservations:
          cpus: '8.0'
          memory: 16G
    
    command: >
      postgres
      -c shared_buffers=${SHARED_BUFFERS:-8GB}
      -c effective_cache_size=${EFFECTIVE_CACHE_SIZE:-16GB}
      -c maintenance_work_mem=${MAINTENANCE_WORK_MEM:-2GB}
      -c work_mem=${WORK_MEM:-128MB}
      -c max_connections=${MAX_CONNECTIONS:-200}
      -c max_parallel_workers=${MAX_PARALLEL_WORKERS:-8}
      -c max_parallel_workers_per_gather=${MAX_PARALLEL_WORKERS_PER_GATHER:-4}
      -c max_parallel_maintenance_workers=${MAX_PARALLEL_MAINTENANCE_WORKERS:-4}
      -c max_worker_processes=${MAX_WORKER_PROCESSES:-16}
      -c random_page_cost=1.1
      -c effective_io_concurrency=200
      -c shared_preload_libraries='pg_stat_statements'

volumes:
  postgres_data:
    driver: local
```

### 4. 이미지 빌드 및 재시작

```bash
# 1. 현재 컨테이너 중지 (데이터는 volume에 유지됨)
docker-compose down

# 2. 새 이미지 빌드
docker-compose build

# 3. 컨테이너 시작
docker-compose up -d

# 4. 로그 확인
docker-compose logs -f postgres
```

### 5. pgvector extension 수동 설치

```bash
# DB 접속
docker-compose exec postgres psql -U myapp_admin -d myapp_db
```

PostgreSQL 셸에서 실행:

```sql
-- 1. vector_data 스키마 생성
CREATE SCHEMA IF NOT EXISTS vector_data;

-- 2. pgvector extension 설치 (vector_data 스키마에)
CREATE EXTENSION IF NOT EXISTS vector SCHEMA vector_data;

-- 3. 설치 확인
SELECT extname, extversion, nspname 
FROM pg_extension e 
JOIN pg_namespace n ON e.extnamespace = n.oid 
WHERE extname IN ('postgis', 'vector')
ORDER BY extname;

-- 4. search_path 설정
ALTER DATABASE myapp_db SET search_path TO public, vector_data;

-- 5. 현재 세션에 적용
SET search_path TO public, vector_data;

-- 6. 확인
SHOW search_path;

-- 7. 테스트 테이블 생성
CREATE TABLE vector_data.embeddings (
    id BIGSERIAL PRIMARY KEY,
    content TEXT,
    embedding vector(1536),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 8. PostGIS 테이블 예제 (기존 스키마, 영향 없음)
-- CREATE TABLE public.locations (
--     id BIGSERIAL PRIMARY KEY,
--     name TEXT,
--     geom GEOMETRY(Point, 4326)
-- );

-- 9. 스키마별 테이블 확인
\dt public.*
\dt vector_data.*

-- 10. Extension 목록
\dx
```

### 6. 자동화 스크립트 (선택사항)

`migration-scripts/add-pgvector.sql` 생성:

```sql
-- 이 스크립트는 기존 DB에 pgvector를 추가합니다
-- 주의: docker-entrypoint-initdb.d는 DB가 비어있을 때만 실행됩니다

DO $$
BEGIN
    -- vector_data 스키마 생성
    CREATE SCHEMA IF NOT EXISTS vector_data;
    
    -- pgvector extension 설치
    CREATE EXTENSION IF NOT EXISTS vector SCHEMA vector_data;
    
    RAISE NOTICE 'pgvector extension installed successfully in vector_data schema';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error installing pgvector: %', SQLERRM;
END $$;

-- search_path 설정
DO $$
BEGIN
    EXECUTE 'ALTER DATABASE ' || current_database() || ' SET search_path TO public, vector_data';
    RAISE NOTICE 'search_path updated';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error updating search_path: %', SQLERRM;
END $$;

-- 예제 테이블
CREATE TABLE IF NOT EXISTS vector_data.embeddings (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 설치 확인
SELECT 
    extname,
    extversion,
    nspname as schema_name
FROM pg_extension e
JOIN pg_namespace n ON e.extnamespace = n.oid
WHERE extname IN ('postgis', 'vector')
ORDER BY extname;
```

**수동 실행:**
```bash
docker-compose exec postgres psql -U myapp_admin -d myapp_db -f /docker-entrypoint-initdb.d/add-pgvector.sql
```

### 7. 설치 확인

```bash
# Extension 목록
docker-compose exec postgres psql -U myapp_admin -d myapp_db -c "\dx"

# 상세 정보
docker-compose exec postgres psql -U myapp_admin -d myapp_db -c "
SELECT 
    extname,
    extversion,
    nspname as schema_name
FROM pg_extension e
JOIN pg_namespace n ON e.extnamespace = n.oid
WHERE extname IN ('postgis', 'postgis_topology', 'postgis_raster', 'vector')
ORDER BY extname;
"

# 스키마 확인
docker-compose exec postgres psql -U myapp_admin -d myapp_db -c "\dn+"

# 테이블 확인
docker-compose exec postgres psql -U myapp_admin -d myapp_db -c "
SELECT schemaname, tablename 
FROM pg_tables 
WHERE schemaname IN ('public', 'vector_data')
ORDER BY schemaname, tablename;
"
```

### 8. 애플리케이션 코드 예제

#### PostGIS와 pgvector 함께 사용

```python
import psycopg2
from pgvector.psycopg2 import register_vector

conn = psycopg2.connect(
    host="localhost",
    database="myapp_db",
    user="myapp_admin",
    password="YourSecurePassword123!@#",
    options="-c search_path=public,vector_data"
)

register_vector(conn)
cur = conn.cursor()

# PostGIS 쿼리 (public 스키마)
cur.execute("""
    SELECT name, ST_AsText(geom) 
    FROM public.locations 
    WHERE ST_DWithin(
        geom, 
        ST_SetSRID(ST_MakePoint(126.9780, 37.5665), 4326)::geography, 
        1000
    )
""")

# pgvector 쿼리 (vector_data 스키마)
query_vector = [0.1] * 1536
cur.execute("""
    SELECT content, embedding <=> %s AS distance
    FROM vector_data.embeddings
    ORDER BY embedding <=> %s
    LIMIT 5
""", (query_vector, query_vector))
```

### 9. 트러블슈팅

**문제 1: Extension을 찾을 수 없음**

```bash
# 컨테이너 내부 확인
docker-compose exec postgres bash

# pgvector 설치 확인
ls -la /usr/lib/postgresql/16/lib/ | grep vector
ls -la /usr/share/postgresql/16/extension/ | grep vector

# 수동 설치 (필요시)
cd /tmp
git clone --branch v0.8.1 https://github.com/pgvector/pgvector.git
cd pgvector
make
make install
```

**문제 2: 권한 오류**

```sql
-- 스키마 소유자 확인
SELECT nspname, nspowner::regrole 
FROM pg_namespace 
WHERE nspname = 'vector_data';

-- 권한 재설정
GRANT ALL ON SCHEMA vector_data TO myapp_admin;
GRANT ALL ON ALL TABLES IN SCHEMA vector_data TO myapp_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA vector_data 
    GRANT ALL ON TABLES TO myapp_admin;
```

**문제 3: search_path 적용 안됨**

```sql
-- 데이터베이스 레벨 확인
SELECT datname, datconfig 
FROM pg_database 
WHERE datname = 'myapp_db';

-- 재설정
ALTER DATABASE myapp_db SET search_path TO public, vector_data;

-- 세션 재연결 후 확인
SHOW search_path;
```

**문제 4: 기존 데이터 영향**

```sql
-- PostGIS 테이블 확인
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename LIKE '%geom%';

-- Vector 테이블 확인
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'vector_data';

-- 각 스키마는 완전히 독립적
-- PostGIS: public 스키마
-- pgvector: vector_data 스키마
```

---

## 성능 최적화 가이드

### 시스템 리소스별 권장 설정

#### 메모리 설정

| 시스템 메모리 | shared_buffers | effective_cache_size | maintenance_work_mem | work_mem |
|--------------|----------------|---------------------|---------------------|----------|
| 8GB | 2GB | 6GB | 512MB | 32MB |
| 16GB | 4GB | 12GB | 1GB | 64MB |
| 32GB | 8GB | 24GB | 2GB | 128MB |
| 64GB | 16GB | 48GB | 4GB | 256MB |
| 128GB | 32GB | 96GB | 8GB | 512MB |

#### CPU 설정

| CPU 코어 | max_parallel_workers | max_parallel_workers_per_gather | max_worker_processes |
|----------|---------------------|--------------------------------|---------------------|
| 4 | 4 | 2 | 8 |
| 8 | 8 | 4 | 16 |
| 16 | 16 | 8 | 32 |
| 32 | 32 | 16 | 64 |

### .env 파일 예제 (시스템별)

#### 8GB RAM, 4 Core

```bash
POSTGRES_USER=myapp_admin
POSTGRES_PASSWORD=YourSecurePassword123!@#
POSTGRES_DB=myapp_db

MAX_CONNECTIONS=100
SHARED_BUFFERS=2GB
EFFECTIVE_CACHE_SIZE=6GB
MAINTENANCE_WORK_MEM=512MB
WORK_MEM=32MB
MAX_PARALLEL_WORKERS=4
MAX_PARALLEL_WORKERS_PER_GATHER=2
MAX_PARALLEL_MAINTENANCE_WORKERS=2
MAX_WORKER_PROCESSES=8
```

#### 32GB RAM, 8 Core (권장)

```bash
POSTGRES_USER=myapp_admin
POSTGRES_PASSWORD=YourSecurePassword123!@#
POSTGRES_DB=myapp_db

MAX_CONNECTIONS=200
SHARED_BUFFERS=8GB
EFFECTIVE_CACHE_SIZE=24GB
MAINTENANCE_WORK_MEM=2GB
WORK_MEM=128MB
MAX_PARALLEL_WORKERS=8
MAX_PARALLEL_WORKERS_PER_GATHER=4
MAX_PARALLEL_MAINTENANCE_WORKERS=4
MAX_WORKER_PROCESSES=16
```

#### 64GB RAM, 16 Core

```bash
POSTGRES_USER=myapp_admin
POSTGRES_PASSWORD=YourSecurePassword123!@#
POSTGRES_DB=myapp_db

MAX_CONNECTIONS=300
SHARED_BUFFERS=16GB
EFFECTIVE_CACHE_SIZE=48GB
MAINTENANCE_WORK_MEM=4GB
WORK_MEM=256MB
MAX_PARALLEL_WORKERS=16
MAX_PARALLEL_WORKERS_PER_GATHER=8
MAX_PARALLEL_MAINTENANCE_WORKERS=8
MAX_WORKER_PROCESSES=32
```

---

## 다음 단계

설치가 완료되었다면:
1. [02. 시작하기](../02-getting-started/) - pgvector 기본 사용법
2. [06. 인덱싱](../06-indexing/) - 성능 최적화를 위한 인덱스 생성