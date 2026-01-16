# 14. 실전 활용 사례 (Use Cases)

pgvector를 활용한 실제 프로젝트 사례와 구현 방법을 다룹니다.

## 목차
- [의미론적 검색 (Semantic Search)](#의미론적-검색)
- [추천 시스템 (Recommendation System)](#추천-시스템)
- [이미지 유사도 검색 (Image Similarity Search)](#이미지-유사도-검색)
- [RAG 시스템 (Retrieval-Augmented Generation)](#rag-시스템)

---

## 의미론적 검색 (Semantic Search)

### 개념
의미론적 검색은 키워드 매칭이 아닌 **의미의 유사성**을 기반으로 문서를 검색하는 방법입니다. 사용자의 질문과 의미가 유사한 문서를 찾아냅니다.

### 아키텍처

```
사용자 쿼리 → 임베딩 모델 → 쿼리 벡터 → pgvector 검색 → 관련 문서
     ↓                                              ↑
문서 컬렉션 → 임베딩 모델 → 문서 벡터 → pgvector 저장
```

### 구현 예제

#### 1. 테이블 생성
```sql
CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    title TEXT,
    content TEXT,
    embedding vector(1536),  -- OpenAI ada-002 차원
    created_at TIMESTAMP DEFAULT NOW()
);

-- 벡터 인덱스 생성 (코사인 거리 사용)
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);
```

#### 2. 문서 임베딩 및 저장 (Python)
```python
import openai
import psycopg2
from pgvector.psycopg2 import register_vector

# 연결 설정
conn = psycopg2.connect("dbname=mydb")
register_vector(conn)

# 임베딩 생성
def get_embedding(text):
    response = openai.Embedding.create(
        input=text,
        model="text-embedding-ada-002"
    )
    return response['data'][0]['embedding']

# 문서 저장
documents = [
    {"title": "Python 기초", "content": "Python은 쉽고 강력한 프로그래밍 언어입니다."},
    {"title": "PostgreSQL 소개", "content": "PostgreSQL은 오픈소스 관계형 데이터베이스입니다."},
]

cur = conn.cursor()
for doc in documents:
    embedding = get_embedding(doc['content'])
    cur.execute(
        "INSERT INTO documents (title, content, embedding) VALUES (%s, %s, %s)",
        (doc['title'], doc['content'], embedding)
    )
conn.commit()
```

#### 3. 검색 수행
```python
# 쿼리 임베딩 생성
query = "데이터베이스를 배우고 싶어요"
query_embedding = get_embedding(query)

# 유사 문서 검색
cur.execute("""
    SELECT title, content, 1 - (embedding <=> %s) AS similarity
    FROM documents
    ORDER BY embedding <=> %s
    LIMIT 5
""", (query_embedding, query_embedding))

results = cur.fetchall()
for title, content, similarity in results:
    print(f"{title} (유사도: {similarity:.3f})")
    print(f"  {content}\n")
```

### 고급 기능: 필터링과 함께 사용

```sql
-- 특정 카테고리 내에서 검색
SELECT title, content
FROM documents
WHERE category = 'tutorial'
ORDER BY embedding <=> '[query_embedding]'
LIMIT 5;

-- 날짜 범위 필터링
SELECT title, content
FROM documents
WHERE created_at >= '2024-01-01'
ORDER BY embedding <=> '[query_embedding]'
LIMIT 5;
```

### 성능 최적화 팁
- **배치 임베딩**: 여러 문서를 한 번에 임베딩하여 API 호출 최소화
- **캐싱**: 자주 검색되는 쿼리의 임베딩을 캐시
- **청크 분할**: 긴 문서는 작은 청크로 나누어 저장 (512-1024 토큰)
- **하이브리드 검색**: 키워드 검색과 벡터 검색을 결합

---

## 추천 시스템 (Recommendation System)

### 개념
사용자의 선호도나 아이템의 특성을 벡터로 표현하여 유사한 아이템을 추천하는 시스템입니다.

### 추천 전략

1. **Content-Based Filtering**: 아이템의 특성(콘텐츠) 기반 추천
2. **Collaborative Filtering**: 사용자 행동 패턴 기반 추천
3. **Hybrid Approach**: 두 방식의 결합

### 구현 예제: 상품 추천

#### 1. 테이블 설계
```sql
-- 상품 테이블
CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    name TEXT,
    description TEXT,
    category TEXT,
    price DECIMAL(10, 2),
    embedding vector(768)  -- 상품 특성 벡터
);

-- 사용자 선호도 테이블
CREATE TABLE user_preferences (
    user_id BIGINT,
    product_id BIGINT,
    rating DECIMAL(3, 2),
    interaction_type TEXT,  -- 'view', 'purchase', 'like'
    created_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX ON products USING hnsw (embedding vector_cosine_ops);
```

#### 2. 상품 기반 추천 (Similar Items)
```sql
-- 특정 상품과 유사한 상품 찾기
SELECT 
    p2.id,
    p2.name,
    p2.category,
    1 - (p1.embedding <=> p2.embedding) AS similarity
FROM products p1
CROSS JOIN products p2
WHERE p1.id = 123  -- 기준 상품 ID
  AND p2.id != 123
ORDER BY p1.embedding <=> p2.embedding
LIMIT 10;
```

#### 3. 사용자 맞춤 추천
```python
# 사용자가 좋아한 상품들의 평균 벡터 계산
def get_user_preference_vector(user_id):
    cur.execute("""
        SELECT AVG(p.embedding) as pref_vector
        FROM user_preferences up
        JOIN products p ON up.product_id = p.id
        WHERE up.user_id = %s
          AND up.rating >= 4.0
    """, (user_id,))
    
    return cur.fetchone()[0]

# 사용자 선호도 기반 추천
user_vector = get_user_preference_vector(user_id=456)

cur.execute("""
    SELECT id, name, category, price
    FROM products
    WHERE id NOT IN (
        SELECT product_id FROM user_preferences WHERE user_id = 456
    )
    ORDER BY embedding <=> %s
    LIMIT 20
""", (user_vector,))
```

#### 4. 카테고리 내 추천 (필터링)
```sql
-- 같은 카테고리 내에서 유사 상품 추천
SELECT 
    id,
    name,
    price,
    1 - (embedding <=> '[target_embedding]') AS similarity
FROM products
WHERE category = 'electronics'
ORDER BY embedding <=> '[target_embedding]'
LIMIT 10;
```

### 추천 시스템 고도화

#### 다중 요소 고려
```python
# 가중치를 적용한 추천
def weighted_recommendation(user_vector, category_filter=None, price_range=None):
    query = """
        SELECT 
            id, 
            name,
            category,
            price,
            (1 - (embedding <=> %s)) AS similarity,
            -- 가격 점수 (정규화)
            1 - ABS(price - %s) / %s AS price_score,
            -- 최종 점수
            (1 - (embedding <=> %s)) * 0.7 + 
            (1 - ABS(price - %s) / %s) * 0.3 AS final_score
        FROM products
        WHERE 1=1
    """
    
    params = [user_vector, target_price, max_price_diff, 
              user_vector, target_price, max_price_diff]
    
    if category_filter:
        query += " AND category = %s"
        params.append(category_filter)
    
    query += " ORDER BY final_score DESC LIMIT 20"
    
    cur.execute(query, params)
    return cur.fetchall()
```

---

## 이미지 유사도 검색 (Image Similarity Search)

### 개념
이미지의 시각적 특징을 벡터로 표현하여 유사한 이미지를 찾는 시스템입니다.

### 사용 사례
- **역이미지 검색**: Google 이미지 검색과 유사
- **중복 이미지 탐지**: 동일하거나 유사한 이미지 찾기
- **상품 이미지 검색**: 쇼핑몰에서 비슷한 상품 찾기

### 구현 예제

#### 1. 테이블 설계
```sql
CREATE TABLE images (
    id BIGSERIAL PRIMARY KEY,
    filename TEXT,
    url TEXT,
    category TEXT,
    embedding vector(512),  -- ResNet, CLIP 등의 모델 사용
    metadata JSONB,
    uploaded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX ON images USING hnsw (embedding vector_cosine_ops);
```

#### 2. 이미지 임베딩 생성 (Python + CLIP)
```python
import torch
from PIL import Image
from transformers import CLIPProcessor, CLIPModel

# CLIP 모델 로드
model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

def get_image_embedding(image_path):
    image = Image.open(image_path)
    inputs = processor(images=image, return_tensors="pt")
    
    with torch.no_grad():
        image_features = model.get_image_features(**inputs)
    
    # 정규화
    embedding = image_features / image_features.norm(dim=-1, keepdim=True)
    return embedding[0].numpy().tolist()

# 이미지 저장
image_path = "product_image.jpg"
embedding = get_image_embedding(image_path)

cur.execute("""
    INSERT INTO images (filename, url, category, embedding)
    VALUES (%s, %s, %s, %s)
""", ("product_image.jpg", "https://...", "fashion", embedding))
conn.commit()
```

#### 3. 유사 이미지 검색
```python
# 업로드된 이미지와 유사한 이미지 찾기
query_image_path = "query_image.jpg"
query_embedding = get_image_embedding(query_image_path)

cur.execute("""
    SELECT 
        id,
        filename,
        url,
        category,
        1 - (embedding <=> %s) AS similarity
    FROM images
    ORDER BY embedding <=> %s
    LIMIT 10
""", (query_embedding, query_embedding))

similar_images = cur.fetchall()
```

#### 4. 텍스트로 이미지 검색 (CLIP 활용)
```python
def text_to_image_search(text_query):
    # 텍스트를 이미지 공간의 벡터로 변환
    inputs = processor(text=[text_query], return_tensors="pt")
    
    with torch.no_grad():
        text_features = model.get_text_features(**inputs)
    
    text_embedding = text_features / text_features.norm(dim=-1, keepdim=True)
    embedding_list = text_embedding[0].numpy().tolist()
    
    # 이미지 검색
    cur.execute("""
        SELECT id, filename, url, 1 - (embedding <=> %s) AS similarity
        FROM images
        ORDER BY embedding <=> %s
        LIMIT 10
    """, (embedding_list, embedding_list))
    
    return cur.fetchall()

# 사용 예
results = text_to_image_search("빨간 드레스를 입은 여성")
```

### 이미지 중복 탐지
```sql
-- 매우 유사한 이미지 찾기 (임계값 사용)
WITH duplicates AS (
    SELECT 
        i1.id AS image1_id,
        i2.id AS image2_id,
        1 - (i1.embedding <=> i2.embedding) AS similarity
    FROM images i1
    CROSS JOIN images i2
    WHERE i1.id < i2.id
      AND 1 - (i1.embedding <=> i2.embedding) > 0.95  -- 95% 이상 유사
)
SELECT * FROM duplicates ORDER BY similarity DESC;
```

---

## RAG 시스템 (Retrieval-Augmented Generation)

### 개념
대규모 문서에서 관련 정보를 검색(Retrieval)하여 LLM의 생성(Generation) 품질을 향상시키는 시스템입니다.

### RAG 워크플로우

```
1. 문서 수집 및 전처리
2. 청크 분할 (Chunking)
3. 임베딩 생성 및 저장
4. 사용자 질문 → 임베딩
5. 관련 문서 검색 (pgvector)
6. Context + 질문 → LLM
7. 답변 생성
```

### 구현 예제

#### 1. 문서 저장 테이블
```sql
CREATE TABLE knowledge_base (
    id BIGSERIAL PRIMARY KEY,
    document_id TEXT,
    chunk_index INTEGER,
    content TEXT,
    embedding vector(1536),
    metadata JSONB,  -- source, page_number, section 등
    created_at TIMESTAMP DEFAULT NOW()
);

-- 효율적인 검색을 위한 인덱스
CREATE INDEX ON knowledge_base USING hnsw (embedding vector_cosine_ops);
CREATE INDEX ON knowledge_base (document_id);
CREATE INDEX ON knowledge_base USING GIN (metadata);
```

#### 2. 문서 처리 및 저장 (Python)
```python
from langchain.text_splitter import RecursiveCharacterTextSplitter
import openai

def process_document(file_path, document_id):
    # 문서 읽기
    with open(file_path, 'r', encoding='utf-8') as f:
        text = f.read()
    
    # 청크로 분할 (오버랩 포함)
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200,
        length_function=len,
    )
    chunks = text_splitter.split_text(text)
    
    # 각 청크를 임베딩하고 저장
    for idx, chunk in enumerate(chunks):
        embedding = get_embedding(chunk)
        
        cur.execute("""
            INSERT INTO knowledge_base 
            (document_id, chunk_index, content, embedding, metadata)
            VALUES (%s, %s, %s, %s, %s)
        """, (
            document_id,
            idx,
            chunk,
            embedding,
            {"source": file_path, "chunk_size": len(chunk)}
        ))
    
    conn.commit()
```

#### 3. 관련 문서 검색
```python
def retrieve_relevant_context(question, top_k=5):
    # 질문 임베딩
    question_embedding = get_embedding(question)
    
    # 관련 문서 검색
    cur.execute("""
        SELECT 
            content,
            metadata,
            1 - (embedding <=> %s) AS similarity
        FROM knowledge_base
        ORDER BY embedding <=> %s
        LIMIT %s
    """, (question_embedding, question_embedding, top_k))
    
    results = cur.fetchall()
    
    # Context 구성
    context = "\n\n---\n\n".join([row[0] for row in results])
    return context, results
```

#### 4. LLM과 통합 (OpenAI API)
```python
def rag_query(question):
    # 1. 관련 문서 검색
    context, sources = retrieve_relevant_context(question, top_k=3)
    
    # 2. 프롬프트 구성
    prompt = f"""다음 문서를 참고하여 질문에 답변해주세요.

문서 내용:
{context}

질문: {question}

답변:"""
    
    # 3. LLM 호출
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "당신은 주어진 문서를 기반으로 정확하게 답변하는 도우미입니다."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.3
    )
    
    answer = response['choices'][0]['message']['content']
    
    return {
        "answer": answer,
        "sources": [s[1] for s in sources],  # metadata
        "similarities": [s[2] for s in sources]
    }

# 사용 예
result = rag_query("PostgreSQL의 HNSW 인덱스는 무엇인가요?")
print(result['answer'])
print(f"\n참고 문서: {result['sources']}")
```

### 고급 RAG 기법

#### 1. 하이브리드 검색 (벡터 + 키워드)
```sql
-- Full-text search와 벡터 검색 결합
WITH vector_results AS (
    SELECT id, content, embedding <=> '[query_embedding]' AS vec_distance
    FROM knowledge_base
    ORDER BY vec_distance
    LIMIT 20
),
keyword_results AS (
    SELECT id, content, ts_rank(to_tsvector('korean', content), query) AS rank
    FROM knowledge_base, plainto_tsquery('korean', '검색어') query
    WHERE to_tsvector('korean', content) @@ query
    ORDER BY rank DESC
    LIMIT 20
)
SELECT DISTINCT
    kb.id,
    kb.content,
    COALESCE(vr.vec_distance, 1) AS vec_score,
    COALESCE(kr.rank, 0) AS keyword_score,
    (COALESCE(1 - vr.vec_distance, 0) * 0.7 + COALESCE(kr.rank, 0) * 0.3) AS final_score
FROM knowledge_base kb
LEFT JOIN vector_results vr ON kb.id = vr.id
LEFT JOIN keyword_results kr ON kb.id = kr.id
WHERE vr.id IS NOT NULL OR kr.id IS NOT NULL
ORDER BY final_score DESC
LIMIT 5;
```

#### 2. 메타데이터 필터링
```python
def filtered_rag_query(question, filters=None):
    question_embedding = get_embedding(question)
    
    query = """
        SELECT content, metadata, 1 - (embedding <=> %s) AS similarity
        FROM knowledge_base
        WHERE 1=1
    """
    params = [question_embedding]
    
    # 메타데이터 필터 적용
    if filters:
        if 'document_type' in filters:
            query += " AND metadata->>'type' = %s"
            params.append(filters['document_type'])
        
        if 'date_after' in filters:
            query += " AND (metadata->>'date')::date >= %s"
            params.append(filters['date_after'])
    
    query += " ORDER BY embedding <=> %s LIMIT %s"
    params.extend([question_embedding, 5])
    
    cur.execute(query, params)
    return cur.fetchall()
```

#### 3. Re-ranking
```python
from sentence_transformers import CrossEncoder

# Cross-encoder 모델로 재정렬
cross_encoder = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')

def rerank_results(question, initial_results, top_k=3):
    # 질문-문서 쌍 생성
    pairs = [[question, doc[0]] for doc in initial_results]
    
    # Re-ranking 점수 계산
    scores = cross_encoder.predict(pairs)
    
    # 점수 기준 정렬
    ranked_results = sorted(
        zip(initial_results, scores),
        key=lambda x: x[1],
        reverse=True
    )
    
    return ranked_results[:top_k]
```

### RAG 성능 최적화

1. **청킹 전략**
   - 적절한 청크 크기 선택 (512-1024 토큰)
   - 오버랩 설정 (10-20%)
   - 문맥 유지를 위한 경계 설정

2. **인덱스 최적화**
   - HNSW 파라미터 튜닝
   - `ef_search` 조정으로 recall 개선

3. **캐싱**
   - 자주 검색되는 질문 캐싱
   - 임베딩 결과 캐싱

4. **배치 처리**
   - 여러 문서를 동시에 처리
   - 임베딩 API 호출 최적화

---

## 성능 비교 및 베스트 프랙티스

### 벡터 차원 선택
| 모델 | 차원 | 용도 | 성능 |
|------|------|------|------|
| OpenAI ada-002 | 1536 | 범용 텍스트 | 높음 |
| BERT-base | 768 | 텍스트 분류 | 중간 |
| ResNet-50 | 2048 | 이미지 | 높음 |
| CLIP | 512 | 멀티모달 | 높음 |

### 인덱스 선택 가이드
- **HNSW**: 높은 recall이 중요한 경우 (추천, RAG)
- **IVFFlat**: 빠른 인덱스 구축이 필요한 경우
- **필터링**: WHERE 절이 자주 사용되는 경우 파티셔닝 고려

### 일반적인 함정 및 해결책
1. **차원의 저주**: 고차원 벡터는 성능 저하 → PCA/차원 축소 고려
2. **콜드 스타트**: 신규 아이템/사용자 → 콘텐츠 기반 방식 병행
3. **데이터 편향**: 불균형한 데이터 → 데이터 증강 또는 샘플링

---

## 다음 단계

실전 활용 사례를 학습한 후:
1. [FAQ & 참고 자료](./15-references/) - 자주 묻는 질문과 추가 자료
2. 실제 프로젝트에 적용해보기
3. 성능 모니터링 및 최적화

