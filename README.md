# 📘 pgvector 개요

## 1. 정의
pgvector는 PostgreSQL에서 **벡터 유사도 검색**을 가능하게 하는 오픈소스 확장 프로그램.

## 2. 주요 특징 (장점)
**PostgreSQL의 강력함과 벡터 검색의 결합**
- 기존 인프라 활용: 별도 벡터 DB 불필요
- 오픈소스: 무료, 커뮤니티 지원

## 3. 벡터 데이터베이스 비교

| 특징 | pgvector | Pinecone | Milvus | Weaviate | Chroma |
|------|----------|----------|--------|----------|--------|
| **타입** | PostgreSQL 확장 | 클라우드 서비스 | 독립형 DB | 독립형 DB | 독립형 DB |
| **배포** | 온프레미스 | 클라우드 전용 | 온프레미스/클라우드 | 온프레미스/클라우드 | 온프레미스/클라우드 |
| **설치** | 쉬움 | 불필요 | 복잡 | 중간 | 매우 쉬움 |
| **비용** | 무료 | 유료 (사용량 기반) | 무료 | 무료/유료 | 무료 |
| **관계형 JOIN** | ✅ 완벽 지원 | ❌ | 제한적 | 제한적 | ❌ |
| **ACID 보장** | ✅ | ❌ | ❌ | 제한적 | ❌ |
| **학습 곡선** | 낮음 (SQL) | 낮음 | 높음 | 중간 | 매우 낮음 |
| **확장성** | 수억 벡터 | 무제한 | 무제한 | 수억 벡터 | 수백만 벡터 |
| **인프라** | 기존 PostgreSQL | 관리형 | 자체 관리 필요 | 자체 관리 필요 | 자체 관리/클라우드 |
| **주요 장점** | SQL 통합 | 운영 편의성 | 고성능 | 하이브리드 검색 | 개발 속도 |

## 4. 내가 pgvector를 선택하는 이유
**기존에 사용중인 Postgresql 에 확장 설치가 쉽고 관리가 용이**
- 우리 회사의 경우 대부분이 온프레미스 환경, 고객사는 돈이 없음(비용 절감)
- 이미 대부분의 DB가 PostgreSQL + PostGIS 를 사용 중
- 이중화 및 백업의 고통에서 벗어 나고자
- 백만건 이상의 데이터의 경우 성능 한계 및 Index 이슈 등이 있지만 우리 고객 데이터는  
  그만큼 많지 않음
---

## 5. pgvector를 선택 시 유의 사항
- pgvector를 상용 목적으로 사용하는 경우, R & D에 사용하는 경우에 따라 버전이 달라짐  
  상용의 경우 최신 버전이 아닌 안정적인 버전을 사용하고, R & D의 경우 가능하면 가장 최신 버전을 사용해야  
  성능 및 최신 기능을 맛 볼 수 있음
- 프로젝트 내 service prodvider 형태의 별도 DB로 관리 하는 경우가 아닌 단일 DB를 사용하는 경우라면  
  스키마 분리를 통해, 동일 DB내 업무용 Table과 벡터 Table 이 혼재 되지 않도록 스키마를 분리를 권장
---

# 📖 목차

Milvus / Pinecone / Weaviate / Chroma / pgvector 제일 최신 문서 흐름과 동일하게 재 작성  
- 임베딩 생성 → 저장 → 검색 → 인덱싱

### [01. 설치 ](./01-installation/)
- Docker를 이용한 신규 설치  
- 기 운영중인 Postgresql에 확장 설치

### 02. 시작하기 (Getting Started)
- Extension 활성화
- 벡터 컬럼 생성
- 벡터 삽입
- 최근접 이웃 검색
- 기본 쿼리

### 03. 임베딩 생성 (Embedding Basics)
- 텍스트 임베딩 생성
- 이미지 임베딩 생성
- float32 / half / binary 비교
- 임베딩 차원
- 외부 모델(SentenceTransformers, OpenAI 등) 활용

### 04. 벡터 타입 (Vector Types)
- vector
- halfvec
- bit
- sparsevec
- 거리 함수 연산자 비교

### 05. 벡터 저장 (Storing Vectors)
- Insert / Bulk Insert
- Update / Upsert
- Delete
- 메타데이터 설계
- JSON + vector 구조

### 06. 벡터 쿼리 (Querying Vectors)
- 거리 기반 검색
- top-K 검색
- 필터링 기반 벡터 검색
- exact vs approximate
- re-ranking

### 07. 인덱싱 (Indexing)
- HNSW (m, ef_construction, ef_search)
- IVFFlat (lists, probes)
- Partial Index
- Partitioning
- 인덱스 빌드 시간 및 성능

### 08. 반정밀도 벡터 (Half-Precision)
- halfvec 타입
- halfvec 인덱싱
- halfvec 검색

### 09. 이진 벡터 (Binary Vectors)
- bit 타입
- Binary Quantization
- 재랭킹

### 10. 희소 벡터 (Sparse Vectors)
- sparsevec 구조
- sparsevec 삽입 및 검색

### 11. 하이브리드 검색 (Hybrid Search)
- BM25 + vector
- RRF Fusion
- Cross Encoder 기반 재랭킹

### 12. 서브벡터 (Subvectors)
- Subvector Index
- Expression Indexing
- Subvector Query

### 13. 성능 튜닝 (Performance)
- PostgreSQL 파라미터 튜닝
- 인덱스 최적화
- 검색 최적화
- EXPLAIN ANALYZE
- pg_stat_statements

### 14. 스케일링 (Scaling)
- Vertical Scaling
- Horizontal Scaling
- Replica
- Sharding (Citus)
- 애플리케이션 레벨 샤딩

### 15. 실전 활용 사례 (Use Cases)
- Semantic Search
- RAG 시스템
- 추천 시스템
- 이미지 검색
- 중복 이미지 탐지

### [15. FAQ & 참고 자료](./15-references/)
자주 묻는 질문 및 참고 자료
- **FAQ**
  - 최대 데이터 크기
  - 복제 (Replication) 지원
  - 2,000차원 이상 인덱싱
  - 인덱스 관련 문제 해결
- **참고 자료**
  - 관련 논문
  - 유용한 링크
  - 벡터 타입별 연산자 및 함수 레퍼런스

## 🎯 학습 로드맵

```
1주차: 설치 및 기본기
  ├─ 01. 설치
  ├─ 02. 시작하기
  ├─ 03. 벡터 타입
  ├─ 04. 벡터 저장
  └─ 05. 벡터 쿼리

2주차: 인덱싱 마스터 (가장 중요!)
  └─ 06. 인덱싱 (HNSW, IVFFlat, Filtering)

3주차: 고급 벡터 타입
  ├─ 07. 반정밀도 벡터
  ├─ 08. 이진 벡터
  └─ 09. 희소 벡터

4주차: 고급 기능 및 최적화
  ├─ 10. 하이브리드 검색
  ├─ 11. 서브벡터
  └─ 12. 성능 튜닝

5주차: 실전 적용
  ├─ 13. 스케일링
  └─ 14. 실전 활용 사례 (Semantic Search, 추천, RAG 등)
```

## 🔗 주요 링크

- [pgvector GitHub](https://github.com/pgvector/pgvector)
- [PostgreSQL 공식 문서](https://www.postgresql.org/docs/)
- [pgvector 예제 모음](https://github.com/pgvector/pgvector-python/tree/master/examples)

## 🚀 시작일

2024년 11월 14일

---

**Note**: 이 저장소는 개인 학습 목적으로 작성되었습니다.
