# 📘 05. 벡터 저장 (Storing Vectors)

pgvector에서 벡터 데이터를 저장하고 관리하는 기본 방법을 다룹니다.  
효율적인 저장 구조와 메타데이터 설계는 **검색 성능과 유지보수성**에 직접적인 영향을 미칩니다.

> 🔎 **중요:**  
> 벡터만 저장하는 것이 아니라, **원본 텍스트, 메타데이터, 타임스탬프** 등을 함께 저장해야  
> 검색 결과를 사용자에게 보여주거나 추후 분석 시 활용할 수 있습니다.

> 🎯 **최종 목표:**  
> 이 장에서 배운 저장 방법을 활용하여, 14장에서 [ 논문 PDF RAG 시스템 ] 프로토타입을 구축합니다.
> - 임베딩 모델: `jhgan/ko-sbert-sts` (768차원)
> - 벡터 DB: pgvector + PostgreSQL
> - 응답 LLM : google/flan-t5-base

---

## 1) Insert - 벡터 삽입

### 단순 벡터 삽입

```sql
-- 테이블 생성
CREATE TABLE items (
    id BIGSERIAL PRIMARY KEY,
    embedding vector(3)
);

-- 단건 삽입
INSERT INTO items (embedding) 
VALUES ('[1, 2, 3]');

-- 여러 건 삽입
INSERT INTO items (embedding) 
VALUES 
    ('[1.0, 2.0, 3.0]'),
    ('[4.0, 5.0, 6.0]'),
    ('[7.0, 8.0, 9.0]');

-- 확인
SELECT * FROM items;
```

### 텍스트와 함께 저장

```sql
-- 실용적인 테이블 구조
CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding vector(768),  -- ko-sbert-sts 차원
    created_at TIMESTAMP DEFAULT NOW()
);

-- 삽입
INSERT INTO documents (content, embedding)
VALUES (
    'pgvector는 PostgreSQL의 벡터 검색 확장입니다.',
    '[0.123, -0.456, 0.789, ...]'  -- 768개 값을 다 넣지 않으면 오류 발생
);

-- 그냥 간단히 0으로 768 차원을 넣음
INSERT INTO documents (content, embedding)
VALUES (
    '테스트 문서',
    ARRAY(SELECT 0::float FROM generate_series(1, 768))::vector(768)
);
```

### Python에서 삽입

```python
import psycopg2

conn = psycopg2.connect(
    DB 접속 정보
)
cur = conn.cursor()

# 임베딩 데이터 (Python list)
embedding = [0.1, 0.2, 0.3, ..., 0.768]  # 768개

# 삽입
cur.execute("""
    INSERT INTO documents (content, embedding)
    VALUES (%s, %s)
""", ('문서 내용', embedding))

-- 생략 ---
```

---

## 2) Bulk Insert - 대량 삽입

### VALUES를 이용한 다중 삽입

```sql
-- 여러 건을 한 번에 삽입
INSERT INTO documents (content, embedding)
VALUES 
    ('문서1', '[0.1, 0.2, ...]'),
    ('문서2', '[0.3, 0.4, ...]'),
    ('문서3', '[0.5, 0.6, ...]');
```

### Python execute_batch

```python
from psycopg2.extras import execute_batch

# 대량 데이터 준비
data = [
    ('문서1', [0.1, 0.2, ...]),
    ('문서2', [0.3, 0.4, ...]),
    ('문서3', [0.5, 0.6, ...]),
    # ... 10,000건
]

# 배치 삽입 (1000건씩)
execute_batch(cur, """
    INSERT INTO documents (content, embedding)
    VALUES (%s, %s)
""", data, page_size=1000)

```

### COPY를 이용한 고속 삽입

```python
from io import StringIO
import json

# CSV 형식으로 준비
csv_buffer = StringIO()
for content, embedding in data:
    csv_buffer.write(f"{content}\t{json.dumps(embedding)}\n")

csv_buffer.seek(0)

# COPY 실행 (가장 빠름) --- 나도 안 해 봤음, 굳이 해야 하나 싶기도 하고, 다음에 필요할때 사용
cur.copy_expert("""
    COPY documents (content, embedding)
    FROM STDIN WITH (FORMAT CSV, DELIMITER E'\t')
""", csv_buffer)

conn.commit()
```

### 성능 비교

| 방법 | 10,000건 | 특징 |
|------|---------|------|
| 단건 INSERT | ~60초 | 가장 느림 |
| execute_batch | ~10초 | 적당함 |
| COPY | ~3초 | 가장 빠름 |

---

## 3) Update - 벡터 업데이트

### 단건 업데이트

```sql
-- 특정 ID의 벡터 수정
UPDATE documents 
SET embedding = '[3, 2, 1]' 
WHERE id = 1;

-- 텍스트와 벡터 함께 수정
UPDATE documents
SET 
    content = '수정된 내용',
    embedding = '[0.9, 0.8, 0.7]'
WHERE id = 5;
```

### 조건부 업데이트

```sql
-- 특정 조건의 모든 행 업데이트
UPDATE documents
SET embedding = '[0, 0, 0]'
WHERE content LIKE '%삭제예정%';

-- 타임스탬프 업데이트
UPDATE documents
SET updated_at = NOW()
WHERE id = 10;
```
---

## 4) Upsert - 삽입 또는 업데이트

PostgreSQL의 `ON CONFLICT` 구문 활용

### 기본 Upsert

```sql
-- ID가 존재하면 업데이트, 없으면 삽입
INSERT INTO documents (id, content, embedding)
VALUES (123, '새 내용', '[1, 2, 3]')
ON CONFLICT (id) 
DO UPDATE SET
    content = EXCLUDED.content,         -- EXCLUDED 는 PostgreSQL의 UPSERT(ON CONFLICT) 문법에서만 등장하는 특별한 가상 테이블(alias)
    embedding = EXCLUDED.embedding,
    updated_at = NOW();
```
---

## 5) Delete - 벡터 삭제

### 단건 삭제

```sql
DELETE FROM documents 
WHERE content = '삭제할 내용';
```

### 대량 삭제

```sql
-- 오래된 데이터 삭제
DELETE FROM documents 
WHERE created_at < NOW() - INTERVAL '90 days';

-- 특정 범위 삭제
DELETE FROM documents 
WHERE id BETWEEN 1000 AND 2000;
```

### 삭제 후 정리

```sql
-- 대량 삭제 후 VACUUM 실행 (디스크 공간 회수)
DELETE FROM documents WHERE id < 10000;
VACUUM ANALYZE documents;
```
---

## 6) 메타데이터 설계

### JSONB 타입 활용

JSONB는 JSON 데이터를 이진 형식으로 저장하여 **빠른 검색과 인덱싱**을 지원합니다.
- json : 문자열 그대로 저장. 원본 JSON을 “텍스트 형태”로 보관 (압축·정규화 없음). 공백, key 순서까지 보존됨 
- jsonb : 저장 시 내부적으로 binary 포맷으로 변환하며 key 정렬됨. 공백 제거. key 순서 무시. 중복 key 제거

| 항목        | json | jsonb          |
| --------- | ---- | -------------- |
| 저장 형태     | 텍스트  | 바이너리           |
| key 순서 보존 | O    | X              |
| 중복 key 보존 | O    | X              |
| 저장 속도     | 빠름   | 느림             |
| 검색 속도     | 느림   | 빠름             |
| 인덱스 지원    | X    | O              |
| 실무 권장     | ❌    | **⭕ jsonb 추천** |


```sql
-- 메타데이터 컬럼 추가
CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding vector(768) NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW()
);

-- GIN 인덱스 생성 (JSONB 검색 최적화)
CREATE INDEX ON documents USING gin (metadata);
```

### 메타데이터 예시

```json
{
    "source": "wikipedia",
    "category": "technology",
    "tags": ["database", "vector", "search"],
    "author": "admin",
    "url": "https://example.com/doc123",
    "language": "ko",
    "page_number": 15,
    "confidence": 0.95
}
```

### 메타데이터 삽입

```sql
INSERT INTO documents (content, embedding, metadata)
VALUES (
    '문서 내용',
    '[0.1, 0.2, ...]',
    '{
        "source": "manual",
        "category": "tutorial",
        "tags": ["beginner", "guide"],
        "language": "ko"
    }'::jsonb
);
```

### 메타데이터 쿼리

```sql
-- 특정 키 값으로 검색
SELECT * FROM documents 
WHERE metadata->>'category' = 'technology';

-- 특정 태그 포함 여부
SELECT * FROM documents 
WHERE metadata->'tags' ? 'database';

-- 배열 요소 검색
SELECT * FROM documents 
WHERE metadata @> '{"tags": ["database"]}';

-- 복합 조건
SELECT * FROM documents 
WHERE metadata->>'language' = 'ko'
  AND metadata->>'category' = 'technology'
  AND (metadata->>'confidence')::float > 0.8;

-- 존재 여부 확인
SELECT * FROM documents 
WHERE metadata ? 'page_number';
```

### 메타데이터 업데이트

```sql
-- 전체 교체
UPDATE documents
SET metadata = '{"new": "data"}'
WHERE id = 1;

-- 특정 키만 업데이트
UPDATE documents
SET metadata = metadata || '{"updated": true}'
WHERE id = 1;

-- 키 삭제
UPDATE documents
SET metadata = metadata - 'old_key'
WHERE id = 1;

-- 배열에 요소 추가
UPDATE documents
SET metadata = jsonb_set(
    metadata, 
    '{tags}', 
    (metadata->'tags') || '["new_tag"]'::jsonb
)
WHERE id = 1;
```

---

## 7) JSON + Vector 하이브리드 구조

벡터 검색과 메타데이터 필터링을 결합한 구조

### RAG 최적화 테이블 설계

```sql
CREATE TABLE paper_chunks (
    id bigint PRIMARY KEY,
    
    -- 문서 식별
    document_id bigint NOT NULL,
    chunk_index INT NOT NULL,
    
    -- 내용
    chunk_text TEXT NOT NULL,
    
    -- 벡터 (ko-sbert-sts: 768차원)
    embedding vector(768) NOT NULL,
    
    -- 메타데이터
    metadata JSONB NOT NULL DEFAULT '{}',
    
    updated_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- 제약 조건
    UNIQUE(document_id, chunk_index)
);

-- 인덱스
CREATE INDEX ON paper_chunks USING hnsw (embedding vector_cosine_ops);
CREATE INDEX ON paper_chunks USING gin (metadata);
CREATE INDEX ON paper_chunks (document_id, chunk_index);
CREATE INDEX ON paper_chunks (created_at DESC);
```

### 실제 데이터 삽입

```sql
-- 논문 청크 삽입
INSERT INTO paper_chunks (document_id, chunk_index, chunk_text, embedding, metadata)
VALUES (
    'kim_phd_2024',
    0,
    '수온은 어류의 성장에 중요한 영향을 미친다. 최적 수온 범위는...',
    '[0.123, -0.456, ...]',  -- 768차원
    '{
        "paper_title": "수산 양식 최적화 연구",
        "page_number": 15,
        "section": "연구 방법론",
        "author": "김박사",
        "year": 2024,
        "language": "ko",
        "has_table": false,
        "has_figure": true
    }'::jsonb
);
```

### 하이브리드 검색 쿼리
- 프로젝트 규모와 성격에 따라 아래와 같은 형태가 될 수도 있고, 검색 엔진으로 분리할 수도 있음

```sql
-- 벡터 유사도 + 메타데이터 필터
SELECT 
    document_id,
    chunk_index,
    chunk_text,
    metadata->>'page_number' AS page,
    embedding <=> '[0.234, -0.567, ...]' AS distance
FROM paper_chunks
WHERE 
    metadata->>'language' = 'ko'
    AND metadata->>'section' = '연구 방법론'
    AND (metadata->>'year')::int >= 2020
ORDER BY distance
LIMIT 5;

-- 벡터 검색 + 날짜 범위
SELECT 
    chunk_text,
    metadata,
    embedding <=> '[...]' AS distance
FROM paper_chunks
WHERE 
    created_at >= '2024-01-01'
    AND metadata->>'author' = '김박사'
ORDER BY distance
LIMIT 10;
```

### 같은 문서의 인접 청크 검색

```sql
-- 유사한 청크를 찾고, 그 앞뒤 청크도 함께 가져오기
WITH top_chunks AS (
    SELECT document_id, chunk_index
    FROM paper_chunks
    ORDER BY embedding <=> '[...]'
    LIMIT 3
)
SELECT p.*
FROM paper_chunks p
JOIN top_chunks t ON p.document_id = t.document_id
WHERE p.chunk_index BETWEEN t.chunk_index - 1 AND t.chunk_index + 1
ORDER BY p.document_id, p.chunk_index;
```

---

## 8) 실전 테이블 설계 예시

### 논문 전체 저장 vs 청크 저장

논문을 저장하는 방식은 **논문의 길이**에 따라 선택합니다.

| 방식 | 적합한 경우 | 장점 | 단점 |
|------|------------|------|------|
| **전체 저장** | 3페이지 이하 (2,000자 이하) | 간단한 구조 | 긴 문서는 검색 정확도 낮음 |
| **청크 저장** | 4페이지 이상 (2,000자 이상) | 검색 정확도 높음, RAG 최적화 | 구조 복잡, 저장 공간 더 필요 |

---

### 방식 1: 논문 전체 저장 (짧은 논문용)

**적용 대상:** 논문 요약, 초록, 짧은 보고서 (2,000자 이하)
```sql
-- 논문 전체 테이블
CREATE TABLE papers_full (
    id bigserial PRIMARY KEY,
    paper_id varchar(256) UNIQUE NOT NULL,        -- 논문 고유 ID
    title varchar(256) NOT NULL,                  -- 논문 제목
    author varchar(256),                          -- 저자
    content TEXT NOT NULL,                -- 전체 내용 (통째로)
    embedding vector(768) NOT NULL,       -- 전체 임베딩
    metadata JSONB DEFAULT '{}',
    updated_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);
```

**사용 예시:**
```sql
-- 데이터 삽입
INSERT INTO papers_full (paper_id, title, author, content, embedding, metadata)
VALUES (
    'paper_abstract_001',
    '수산 양식 최적화 연구 초록',
    '김박사',
    '본 연구는 수온이 어류 성장에 미치는 영향을 분석하였다. 실험 결과 25도에서...',
    ARRAY(SELECT 0::float FROM generate_series(1, 768))::vector(768),
    '{"pages": 2, "year": 2024, "type": "abstract"}'::jsonb
);

-- 검색
SELECT paper_id, title, content, 
       embedding <=> '[여기에 질문_임베딩...]' AS distance
FROM papers_full
ORDER BY distance
LIMIT 5;

-- 지금은 embedding 모델이 없어서, 억지로 sql 예제를 만들어 봄
SELECT paper_id, title, content, 
       embedding <=> ARRAY(SELECT 0::float FROM generate_series(1, 768))::vector(768) AS distance
FROM papers_full
ORDER BY distance
LIMIT 5;
```

---

### 방식 2: 논문 청크 저장 (긴 논문용) ✅ 권장

**적용 대상:** 일반 논문, 학위 논문, 긴 보고서 (4페이지 이상, 2,000자 이상)
- author, title 의 경우 논문 데이터가 많지 않을 경우 중복 저장, 많을 경우 테이블을 분리 저장 후 join 사용
```sql
-- 논문 청크 테이블
CREATE TABLE paper_chunks (
    id BIGSERIAL PRIMARY KEY,
    paper_id varchar(256) NOT NULL,                     -- 논문 고유 ID
    chunk_index INT NOT NULL,                           -- 청크 순서 (0부터 시작)
    chunk_text TEXT NOT NULL,                           -- 청크 내용 (500-700자)
    embedding vector(768) NOT NULL,                     -- 청크 임베딩
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- 제약 조건
    UNIQUE(paper_id, chunk_index)
);
```

**메타데이터 예시:**
```json
{
    "paper_title": "수산 양식 최적화 연구",
    "author": "김박사",
    "page_number": 5,
    "section": "연구 방법론",
    "year": 2024,
    "total_pages": 6,
    "total_chunks": 10,
    "language": "ko"
}
```

**사용 예시:**
```sql
-- 데이터 삽입 (논문 1개 = 여러 청크)
INSERT INTO paper_chunks (paper_id, chunk_index, chunk_text, embedding, metadata)
VALUES 
    ('kim_phd_2024', 0, '서론: 본 연구는 수산 양식에서 수온이...', ARRAY(SELECT 0::float FROM generate_series(1, 768))::vector(768),
     '{"paper_title": "양식 최적화", "page_number": 1, "section": "서론"}'::jsonb),
    
    ('kim_phd_2024', 1, '선행 연구: 기존 연구들은 수온 범위를...', ARRAY(SELECT 0::float FROM generate_series(1, 768))::vector(768),
     '{"paper_title": "양식 최적화", "page_number": 1, "section": "선행연구"}'::jsonb),
    
    ('kim_phd_2024', 2, '연구 방법: 실험은 25도 수온에서 진행...', ARRAY(SELECT 0::float FROM generate_series(1, 768))::vector(768),
     '{"paper_title": "양식 최적화", "page_number": 2, "section": "연구방법"}'::jsonb);
```

**특정 논문만 검색:**
```sql
-- 논문 A에서만 검색 (빠름)
SELECT 
    chunk_index,
    chunk_text,
    metadata->>'page_number' AS page,
    metadata->>'section' AS section,
    embedding <=> '[질문_임베딩...]' AS distance
FROM paper_chunks
WHERE paper_id = 'kim_phd_2024'
ORDER BY distance
LIMIT 3;
```

**전체 논문 통합 검색:**
```sql
-- 모든 논문에서 검색
SELECT 
    paper_id,
    metadata->>'paper_title' AS title,
    chunk_index,
    chunk_text,
    metadata->>'page_number' AS page,
    embedding <=> '[질문_임베딩...]' AS distance
FROM paper_chunks
ORDER BY distance
LIMIT 10;
```

**같은 논문의 인접 청크 포함 검색:**
```sql
-- 유사한 청크 + 앞뒤 청크 함께 가져오기
WITH top_chunks AS (
    SELECT paper_id, chunk_index
    FROM paper_chunks
    WHERE paper_id = 'kim_phd_2024'
    ORDER BY embedding <=> '[질문_임베딩...]'
    LIMIT 3
)
SELECT 
    p.chunk_index,
    p.chunk_text,
    p.metadata->>'section' AS section
FROM paper_chunks p
JOIN top_chunks t ON p.paper_id = t.paper_id
WHERE p.chunk_index BETWEEN t.chunk_index - 1 AND t.chunk_index + 1
ORDER BY t.chunk_index, p.chunk_index;
```

---

### 방식 3: 논문 메타 + 청크 분리 (대규모)

**적용 대상:** 수십~수백 개 논문 관리, 논문 메타 정보 별도 관리 필요
```sql
-- 논문 메타데이터 테이블
CREATE TABLE papers_meta (
    id BIGSERIAL PRIMARY KEY,
    paper_id varchar(256) UNIQUE NOT NULL,
    title varchar(256) NOT NULL,
    author varchar(256) NOT NULL,
    abstract TEXT,
    total_pages INT,
    total_chunks INT,
    year INT,
    keywords TEXT[],
    created_at TIMESTAMP DEFAULT NOW()
);

-- 논문 청크 테이블 (외래키 연결)
CREATE TABLE paper_chunks (
    id BIGSERIAL PRIMARY KEY,
    paper_id varchar(256) NOT NULL REFERENCES papers_meta(paper_id) ON DELETE CASCADE,
    chunk_index INT NOT NULL,
    chunk_text TEXT NOT NULL,
    embedding vector(768) NOT NULL,
    page_number INT,
    section TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(paper_id, chunk_index)
);
```

---

### 선택 기준 요약

| 논문 분량 | 테이블 구조 | 이유 |
|----------|------------|------|
| **1-3페이지** | papers_full (전체 저장) | 간단, 빠른 구축 |
| **4-10페이지** | paper_chunks (청크 저장) | 검색 정확도 향상 ✅ |
| **수십 개 이상** | papers_meta + paper_chunks | 메타 관리 편리 |

**당신의 경우 (6-7페이지 논문):**  
→ **paper_chunks 테이블 사용 권장 ✅**

### 청크 크기 권장
```
짧은 청크 (300-500자):
- 장점: 정밀한 검색
- 단점: 문맥 부족, 청크 수 증가

중간 청크 (500-700자): ✅ 권장
- 장점: 정확도와 문맥의 균형
- 단점: 없음

긴 청크 (800-1000자):
- 장점: 충분한 문맥
- 단점: 관련 없는 내용 포함 가능

오버랩: 50-100자 권장
```

---

## 9) 인덱스 및 성능 최적화

벡터 검색 성능을 향상시키기 위한 인덱스 생성과 설정 방법입니다.
- 이 내용은 뒷장 indexing에서 다룰 예정

### 벡터 인덱스 생성

#### HNSW 인덱스 (권장)

**특징:**
- 빠른 검색 속도
- 높은 정확도
- 메모리 사용량 높음
- 10만 건 이하 권장

#### IVFFlat 인덱스 (대용량)

**특징:**
- 10만 건 이상 대용량에 적합
- 속도는 HNSW보다 느림
- 메모리 효율적


### 성능 비교

| 데이터 규모 | 인덱스 없음 | HNSW | IVFFlat |
|-----------|-----------|------|---------|
| 1,000건 | 50ms | 5ms ⚡ | 10ms |
| 10,000건 | 500ms | 10ms ⚡ | 30ms |
| 100,000건 | 5초 | 50ms ⚡ | 100ms |
| 1,000,000건 | 50초 | 200ms | 300ms ⚡ |

**권장:**
- 10만 건 이하: **HNSW**
- 10만 건 이상: **IVFFlat**

---

# 🎯 요약

**벡터 저장 핵심:**

1. **Insert**: 단건/대량 삽입 (COPY가 가장 빠름)
2. **Update**: 벡터 수정 (텍스트 변경 시 임베딩 재생성 필요)
3. **Upsert**: ON CONFLICT로 삽입/업데이트 동시 처리
4. **Delete**: 조건부 삭제 + VACUUM으로 공간 회수
5. **메타데이터**: JSONB 타입 + GIN 인덱스
6. **하이브리드 구조**: 벡터 + 메타데이터 복합 검색
7. **성능 최적화**: HNSW 인덱스 + 파티셔닝 + LIMIT

**권장 테이블 구조 (RAG용):**
```sql
CREATE TABLE rag_chunks (
    id, doc_id, chunk_idx, text,
    embedding vector(768),  -- ko-sbert-sts
    metadata JSONB,
    updated_at, created_at
)
```