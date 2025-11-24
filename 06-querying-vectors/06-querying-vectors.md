# 📘 06. 벡터 쿼리 (Querying Vectors)

pgvector에서 벡터 데이터를 검색하는 다양한 방법을 다룹니다.  
거리 기반 검색, 필터링, 성능 최적화 등 실전에서 필요한 쿼리 패턴을 학습합니다.

> 🎯 **이 문서의 목표:**  
> 논문 PDF에서 질문에 가장 관련된 청크를 정확하고 빠르게 찾는 방법 학습

---

## 1) 거리 기반 검색

벡터 간 거리를 계산하여 유사한 데이터를 찾는 가장 기본적인 검색 방법입니다.

### 기본 구조

```sql
SELECT 
    컬럼들,
    embedding <거리연산자> '쿼리벡터' AS distance
FROM 테이블
ORDER BY distance
LIMIT N;
```

### 거리 연산자 종류

| 연산자 | 거리 함수 | 사용 예시 |
|--------|----------|----------|
| `<->` | L2 Distance (유클리드) | 일반적인 유사도 검색 |
| `<=>` | Cosine Distance | 텍스트 검색 (가장 많이 사용) ✅ |
| `<#>` | Inner Product | 추천 시스템 |

### 실제 예시

```sql
-- 코사인 거리 검색 (텍스트 검색에 가장 적합)
SELECT 
    paper_id,
    chunk_index,
    chunk_text,
    embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks
ORDER BY distance
LIMIT 5;
```

**Python에서 사용:**

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer("jhgan/ko-sbert-sts")
question = "최적 수온은 몇 도인가요?"
query_embedding = model.encode(question).tolist()

cur.execute("""
    SELECT 
        chunk_text,
        metadata->>'page_number' AS page,
        embedding <=> %s AS distance
    FROM paper_chunks
    WHERE paper_id = %s
    ORDER BY distance
    LIMIT 5
""", (query_embedding, 'kim_phd_2024'))

results = cur.fetchall()
for text, page, dist in results:
    print(f"[페이지 {page}] 유사도: {1-dist:.2%}")
    print(text[:100])
```

---

## 2) Top-K 검색 (최근접 이웃)

가장 유사한 K개의 결과를 반환하는 **K-Nearest Neighbors (KNN)** 검색입니다.

### K값 선택 기준

```
K=1:  가장 유사한 1개 (정확한 매칭)
K=3:  상위 3개 (일반적)
K=5:  상위 5개 (균형)
K=10: 상위 10개 (다양성)
K=20: 재순위(Re-ranking) 후보군
```

### 기본 Top-K 검색

```sql
-- Top-5 검색
SELECT 
    paper_id,
    chunk_index,
    chunk_text,
    metadata->>'section' AS section,
    embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks
ORDER BY distance
LIMIT 5;
```

### 특정 논문에서 Top-K 검색

```sql
-- 특정 논문에서만 검색 (더 빠름)
SELECT 
    chunk_index,
    chunk_text,
    metadata->>'page_number' AS page,
    embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks
WHERE paper_id = 'kim_phd_2024'
ORDER BY distance
LIMIT 3;
```

### 거리 임계값 사용

```sql
-- 거리가 0.5 이하인 것만 (유사도 50% 이상)
SELECT 
    chunk_text,
    embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks
WHERE paper_id = 'kim_phd_2024'
  AND embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) < 0.5
ORDER BY distance
LIMIT 10;
```

---

## 3) 필터링 + 벡터 검색 (하이브리드 검색)

메타데이터 조건과 벡터 유사도를 결합한 검색입니다.

### 기본 필터링 검색

```sql
-- 특정 섹션에서만 검색
SELECT 
    chunk_text,
    metadata->>'section' AS section,
    embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks
WHERE metadata->>'section' = '연구 방법론'
ORDER BY distance
LIMIT 5;
```

### 복합 조건 필터링

```sql
-- 여러 조건 결합
SELECT 
    paper_id,
    chunk_text,
    metadata->>'page_number' AS page,
    metadata->>'section' AS section,
    embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks
WHERE 
    metadata->>'language' = 'ko'
    AND (metadata->>'page_number')::int BETWEEN 3 AND 7
    AND metadata->>'section' IN ('연구방법', '실험결과')
ORDER BY distance
LIMIT 10;
```

### 날짜 범위 필터링

```sql
-- 최근 3개월 내 논문만 검색
SELECT 
    paper_id,
    metadata->>'paper_title' AS title,
    chunk_text,
    embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks
WHERE created_at >= NOW() - INTERVAL '3 months'
ORDER BY distance
LIMIT 10;
```

### Python 동적 필터링

```python
def search_with_filters(question, paper_id=None, section=None, page_range=None):
    """동적 필터링 검색"""
    query_embedding = model.encode(question).tolist()
    
    # 기본 쿼리
    sql = """
        SELECT 
            chunk_text,
            metadata->>'page_number' AS page,
            metadata->>'section' AS section,
            embedding <=> %s AS distance
        FROM paper_chunks
        WHERE 1=1
    """
    
    params = [query_embedding]
    
    # 조건 추가
    if paper_id:
        sql += " AND paper_id = %s"
        params.append(paper_id)
    
    if section:
        sql += " AND metadata->>'section' = %s"
        params.append(section)
    
    if page_range:
        sql += " AND (metadata->>'page_number')::int BETWEEN %s AND %s"
        params.extend(page_range)
    
    sql += " ORDER BY distance LIMIT 5"
    
    cur.execute(sql, params)
    return cur.fetchall()

# 사용 예시
results = search_with_filters(
    "수온 영향",
    paper_id='kim_phd_2024',
    section='연구방법',
    page_range=(3, 5)
)
```

---

## 4) Exact vs Approximate 검색

정확도와 속도의 트레이드오프를 이해하고 상황에 맞게 선택합니다.

### Exact Search (정확 검색)

**특징:**
- 모든 벡터와 거리 계산
- 100% 정확한 결과
- 느림 (데이터가 많을수록)

```sql
-- 인덱스 없이 정확 검색 (Sequential Scan)
DROP INDEX IF EXISTS idx_paper_chunks_embedding;

SELECT 
    chunk_text,
    embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks
ORDER BY distance
LIMIT 10;

-- 실행 계획 확인
EXPLAIN ANALYZE ...
-- Seq Scan on paper_chunks (실제 시간: 500ms)
```

### Approximate Search (근사 검색)

**특징:**
- 인덱스 사용 (HNSW, IVFFlat)
- 99%+ 정확도
- 매우 빠름

```sql
-- HNSW 인덱스 생성
CREATE INDEX idx_paper_chunks_embedding 
ON paper_chunks 
USING hnsw (embedding vector_cosine_ops);

-- 근사 검색
SELECT 
    chunk_text,
    embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks
ORDER BY distance
LIMIT 10;

-- 실행 계획 확인
EXPLAIN ANALYZE ...
-- Index Scan using idx_paper_chunks_embedding (실제 시간: 10ms)
```

### 성능 비교

| 방법 | 데이터 규모 | 검색 시간 | 정확도 |
|------|-----------|----------|--------|
| **Exact** | 1,000건 | 50ms | 100% |
| **Exact** | 10,000건 | 500ms | 100% |
| **Exact** | 100,000건 | 5초 | 100% |
| **Approximate (HNSW)** | 1,000건 | 5ms | 99%+ |
| **Approximate (HNSW)** | 10,000건 | 10ms | 99%+ |
| **Approximate (HNSW)** | 100,000건 | 50ms | 99%+ |

### 정확도 조정

```sql
-- 검색 정확도 높이기 (느려짐)
SET hnsw.ef_search = 200;  -- 기본값: 40

SELECT 
    chunk_text,
    embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks
ORDER BY distance
LIMIT 10;

-- 다시 기본값으로
SET hnsw.ef_search = 40;
```

### 선택 기준

```
데이터 1,000건 미만:
→ Exact Search (인덱스 불필요)

데이터 1,000~10,000건:
→ Approximate Search (HNSW)

데이터 10,000건 이상:
→ Approximate Search (HNSW 필수)

정확도가 생명인 경우:
→ Exact Search + 캐싱
```

---

## 5) Re-ranking (재순위)

**Coarse-to-Fine** 전략: 빠른 검색 → 정밀 재정렬

### 전략 1: 많이 가져와서 재정렬

```sql
-- Step 1: 후보 20개 빠르게 추출
WITH candidates AS (
    SELECT 
        id,
        chunk_text,
        embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
    FROM paper_chunks
    WHERE paper_id = 'kim_phd_2024'
    ORDER BY distance
    LIMIT 20  -- 많이 가져옴
)
-- Step 2: 상위 5개만 선택 (추가 로직 가능)
SELECT 
    chunk_text,
    distance
FROM candidates
ORDER BY distance
LIMIT 5;
```

### 전략 2: Binary + Full Vector (Two-Stage)

```sql
-- paper_chunks에 binary 컬럼 추가
ALTER TABLE paper_chunks ADD COLUMN embedding_binary bit(768);

-- binary로 빠르게 1000개 추출 → vector로 정밀 재정렬
WITH candidates AS (
    SELECT id
    FROM paper_chunks
    WHERE paper_id = 'kim_phd_2024'
    ORDER BY embedding_binary <~> B'10101010...'  -- binary 검색 (초고속)
    LIMIT 1000
)
SELECT 
    p.chunk_text,
    p.embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks p
JOIN candidates c ON p.id = c.id
ORDER BY distance
LIMIT 10;
```

### 전략 3: 메타데이터 스코어 결합

```sql
-- 벡터 유사도(70%) + 인기도(30%) 결합
SELECT 
    chunk_text,
    metadata->>'view_count' AS views,
    -- 하이브리드 스코어 계산
    (0.7 * (1 - (embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768)))) +
    (0.3 * LEAST((metadata->>'view_count')::float / 1000, 1.0)) AS hybrid_score
FROM paper_chunks
WHERE paper_id = 'kim_phd_2024'
ORDER BY hybrid_score DESC
LIMIT 10;
```

### 전략 4: 인접 청크 포함

```sql
-- 유사한 청크 찾고 앞뒤 청크도 함께 반환
WITH top_chunks AS (
    SELECT 
        paper_id,
        chunk_index,
        embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
    FROM paper_chunks
    WHERE paper_id = 'kim_phd_2024'
    ORDER BY distance
    LIMIT 3
)
SELECT 
    p.chunk_index,
    p.chunk_text,
    p.metadata->>'section' AS section,
    t.distance
FROM paper_chunks p
JOIN top_chunks t ON p.paper_id = t.paper_id
WHERE p.chunk_index BETWEEN t.chunk_index - 1 AND t.chunk_index + 1
ORDER BY t.distance, p.chunk_index;
```

### Python Re-ranking 예시

```python
def search_and_rerank(question, paper_id, top_k=5, candidate_k=20):
    """후보 추출 → 재정렬"""
    query_embedding = model.encode(question).tolist()
    
    # Step 1: 후보 20개 추출
    cur.execute("""
        SELECT 
            id,
            chunk_text,
            metadata,
            embedding <=> %s AS distance
        FROM paper_chunks
        WHERE paper_id = %s
        ORDER BY distance
        LIMIT %s
    """, (query_embedding, paper_id, candidate_k))
    
    candidates = cur.fetchall()
    
    # Step 2: Python에서 재정렬 (추가 로직)
    reranked = []
    for id, text, metadata, distance in candidates:
        # 재정렬 스코어 계산
        vector_score = 1 - distance
        keyword_score = calculate_keyword_score(text, question)  # 사용자 정의
        
        final_score = 0.7 * vector_score + 0.3 * keyword_score
        reranked.append((text, metadata, final_score))
    
    # Step 3: 상위 K개 반환
    reranked.sort(key=lambda x: x[2], reverse=True)
    return reranked[:top_k]
```

---

## 6) 고급 쿼리 패턴

### 다중 논문 통합 검색

```sql
-- 여러 논문에서 검색 + 논문별 상위 2개씩
WITH ranked AS (
    SELECT 
        paper_id,
        chunk_text,
        metadata->>'paper_title' AS title,
        embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance,
        ROW_NUMBER() OVER (PARTITION BY paper_id ORDER BY embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768)) AS rn
    FROM paper_chunks
)
SELECT 
    paper_id,
    title,
    chunk_text,
    distance
FROM ranked
WHERE rn <= 2  -- 논문별 상위 2개
ORDER BY distance
LIMIT 10;
```

### 제외 검색 (NOT)

```sql
-- 특정 논문 제외
SELECT 
    paper_id,
    chunk_text,
    embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks
WHERE paper_id NOT IN ('old_paper_2020', 'deprecated_paper')
ORDER BY distance
LIMIT 10;
```

### OR 조건 검색

```sql
-- 여러 섹션 중 하나
SELECT 
    chunk_text,
    metadata->>'section' AS section,
    embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768) AS distance
FROM paper_chunks
WHERE metadata->>'section' IN ('서론', '결론', '요약')
ORDER BY distance
LIMIT 10;
```

---

## 7) 성능 최적화 팁

### LIMIT 필수 사용

```sql
-- ❌ 매우 느림 (전체 스캔 후 정렬)
SELECT * FROM paper_chunks
ORDER BY embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768);

-- ✅ 빠름 (상위 K개만 계산)
SELECT * FROM paper_chunks
ORDER BY embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768)
LIMIT 10;
```

### WHERE 조건 먼저

```sql
-- ✅ 좋은 순서: WHERE → ORDER BY
SELECT * FROM paper_chunks
WHERE paper_id = 'kim_phd_2024'  -- 범위 좁힘
ORDER BY embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768)
LIMIT 10;

-- ❌ 나쁜 순서: ORDER BY → WHERE (느림)
SELECT * FROM (
    SELECT * FROM paper_chunks
    ORDER BY embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768)
    LIMIT 100
) sub
WHERE paper_id = 'kim_phd_2024';
```

### 인덱스 활용 확인

```sql
-- 실행 계획 확인
EXPLAIN ANALYZE
SELECT * FROM paper_chunks
WHERE paper_id = 'kim_phd_2024'
ORDER BY embedding <=> ARRAY(SELECT random()::float FROM generate_series(1, 768))::vector(768)
LIMIT 10;

-- "Index Scan using idx_paper_chunks_embedding" 확인
-- Seq Scan이면 인덱스 미사용 → 느림
```

---

## 8) 실전 검색 함수 (Python)

### 기본 검색 함수

```python
from sentence_transformers import SentenceTransformer
import psycopg2

class PaperSearch:
    def __init__(self, conn):
        self.conn = conn
        self.model = SentenceTransformer("jhgan/ko-sbert-sts")
    
    def search(self, question, paper_id=None, top_k=5):
        """기본 검색"""
        query_embedding = self.model.encode(question).tolist()
        cur = self.conn.cursor()
        
        sql = """
            SELECT 
                chunk_text,
                metadata->>'page_number' AS page,
                metadata->>'section' AS section,
                embedding <=> %s AS distance
            FROM paper_chunks
        """
        
        params = [query_embedding]
        
        if paper_id:
            sql += " WHERE paper_id = %s"
            params.append(paper_id)
        
        sql += " ORDER BY distance LIMIT %s"
        params.append(top_k)
        
        cur.execute(sql, params)
        results = cur.fetchall()
        cur.close()
        
        return [
            {
                'text': text,
                'page': page,
                'section': section,
                'similarity': 1 - distance
            }
            for text, page, section, distance in results
        ]

# 사용
searcher = PaperSearch(conn)
results = searcher.search("최적 수온은?", paper_id='kim_phd_2024', top_k=3)

for r in results:
    print(f"[페이지 {r['page']}] 유사도: {r['similarity']:.2%}")
    print(r['text'][:100])
```

---

# 🎯 요약

**벡터 검색 핵심:**

1. **거리 기반 검색**: `<=>` Cosine Distance가 텍스트 검색에 최적
2. **Top-K 검색**: LIMIT으로 상위 K개만 가져오기 (필수!)
3. **필터링**: WHERE 조건으로 범위 좁힌 후 벡터 검색
4. **Exact vs Approximate**: 1,000건 이상이면 인덱스(HNSW) 필수
5. **Re-ranking**: 후보 많이 추출 → 정밀 재정렬

**성능 최적화:**
- LIMIT 필수
- WHERE 조건 먼저
- HNSW 인덱스 생성
- hnsw.ef_search 조정

**실전 패턴:**
```sql
SELECT chunk_text, embedding <=> %s AS distance
FROM paper_chunks
WHERE paper_id = %s  -- 필터링
ORDER BY distance
LIMIT 5;  -- Top-K
```

---