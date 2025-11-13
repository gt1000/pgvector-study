# pgvector Study

PostgreSQL의 벡터 유사도 검색 확장 프로그램인 pgvector를 체계적으로 학습하고 기록하는 저장소입니다.

## 📘 pgvector 개요

### 1. 정의

pgvector는 PostgreSQL에서 **벡터 유사도 검색**을 가능하게 하는 오픈소스 확장 프로그램입니다. AI/ML 애플리케이션에서 생성된 임베딩 벡터를 효율적으로 저장하고 검색할 수 있게 해줍니다.

### 2. 주요 특징 (장점)

**PostgreSQL의 강력함과 벡터 검색의 결합**
- ✅ **ACID 트랜잭션**: 데이터 일관성 보장
- ✅ **관계형 데이터와 통합**: JOIN, WHERE 등 SQL 기능 활용
- ✅ **기존 인프라 활용**: 별도 벡터 DB 불필요
- ✅ **다양한 언어 지원**: Python, Node.js, Java, Go 등 모든 PostgreSQL 클라이언트
- ✅ **오픈소스**: 무료, 커뮤니티 지원

**지원 기능**
- 4가지 벡터 타입: `vector`, `halfvec`, `bit`, `sparsevec`
- 6가지 거리 함수: L2, Inner Product, Cosine, L1, Hamming, Jaccard
- 2가지 인덱스: HNSW (고성능), IVFFlat (빠른 빌드)
- Exact & Approximate 검색

### 3. 벡터 데이터베이스 비교

| 특징 | pgvector | Pinecone | Milvus | Weaviate |
|------|----------|----------|--------|----------|
| **타입** | PostgreSQL 확장 | 클라우드 서비스 | 독립형 DB | 독립형 DB |
| **설치** | 쉬움 | 불필요 | 복잡 | 중간 |
| **비용** | 무료 | 유료 (사용량 기반) | 무료 | 무료/유료 |
| **관계형 JOIN** | ✅ 완벽 지원 | ❌ | 제한적 | 제한적 |
| **ACID 보장** | ✅ | ❌ | ❌ | 제한적 |
| **학습 곡선** | 낮음 (SQL) | 낮음 | 높음 | 중간 |
| **확장성** | 수억 벡터 | 무제한 | 무제한 | 수억 벡터 |
| **인프라** | 기존 PostgreSQL | 관리형 | 자체 관리 필요 | 자체 관리 필요 |

**pgvector를 선택해야 하는 경우**
- 이미 PostgreSQL을 사용 중인 경우
- 벡터와 관계형 데이터를 함께 다뤄야 하는 경우
- 복잡한 JOIN 쿼리가 필요한 경우
- 인프라를 단순하게 유지하고 싶은 경우
- 비용을 절감하고 싶은 경우

---

## 📖 목차

### [01. 설치 (Installation)](./01-installation/)
다양한 환경에서의 pgvector 설치
- Linux & Mac 설치
- Windows 설치
- Docker
- 패키지 매니저 (Homebrew, APT, Yum, PGXN, conda-forge 등)
- 설치 문제 해결

### [02. 시작하기 (Getting Started)](./02-getting-started/)
pgvector의 첫 걸음
- Extension 활성화
- 벡터 컬럼 생성
- 벡터 삽입
- 최근접 이웃 검색
- 기본 쿼리

### [03. 벡터 타입 (Vector Types)](./03-vector-types/)
다양한 벡터 데이터 타입
- `vector` - 단정밀도 벡터 (최대 2,000차원)
- `halfvec` - 반정밀도 벡터 (최대 4,000차원)
- `bit` - 이진 벡터 (최대 64,000차원)
- `sparsevec` - 희소 벡터 (최대 1,000개 non-zero 원소)

### [04. 벡터 저장 (Storing Vectors)](./04-storing-vectors/)
벡터 데이터 저장 및 관리
- 테이블 생성 및 벡터 컬럼 추가
- 벡터 삽입 (Insert)
- 대량 로딩 (Bulk Loading with COPY)
- 벡터 업데이트 (Upsert, Update)
- 벡터 삭제 (Delete)

### [05. 벡터 쿼리 (Querying Vectors)](./05-querying-vectors/)
벡터 검색 쿼리 작성
- 거리 함수 (`<->`, `<#>`, `<=>`, `<+>`, `<~>`, `<%>`)
- 최근접 이웃 검색
- 특정 거리 내 검색
- 거리 계산
- 벡터 집계 (평균, 합계)

### [06. 인덱싱 (Indexing)](./06-indexing/) ⭐ **핵심**
벡터 인덱스 생성 및 최적화
- **HNSW 인덱스**
  - 인덱스 생성 및 파라미터 (`m`, `ef_construction`)
  - 쿼리 옵션 (`ef_search`)
  - 인덱스 빌드 시간 최적화
- **IVFFlat 인덱스**
  - 인덱스 생성 및 파라미터 (`lists`)
  - 쿼리 옵션 (`probes`)
  - 인덱스 빌드 시간 최적화
- **필터링 (Filtering)**
  - WHERE 절과 함께 사용하기
  - Exact 인덱스 vs Approximate 인덱스
  - Partial 인덱싱
  - 파티셔닝
- **반복 인덱스 스캔 (Iterative Index Scans)**
  - Strict Order vs Relaxed Order
  - 스캔 제한 설정

### [07. 반정밀도 벡터 (Half-Precision Vectors)](./07-half-precision-vectors/)
halfvec 타입 활용
- halfvec 테이블 생성
- 반정밀도 인덱싱
- 쿼리 방법

### [08. 이진 벡터 (Binary Vectors)](./08-binary-vectors/)
bit 타입과 Binary Quantization
- 이진 벡터 생성 및 쿼리
- Binary Quantization
- Re-ranking

### [09. 희소 벡터 (Sparse Vectors)](./09-sparse-vectors/)
sparsevec 타입 활용
- 희소 벡터 형식
- 삽입 및 쿼리

### [10. 하이브리드 검색 (Hybrid Search)](./10-hybrid-search/)
벡터 검색과 전체 텍스트 검색 결합
- Full-text Search와 결합
- Reciprocal Rank Fusion (RRF)
- Cross-encoder

### [11. 서브벡터 (Subvectors)](./11-subvectors/)
서브벡터 인덱싱 및 검색
- Expression 인덱싱
- Re-ranking

### [12. 성능 튜닝 (Performance)](./12-performance/)
성능 최적화 기법
- PostgreSQL 서버 파라미터 설정
- 대량 데이터 로딩
- 인덱스 최적화
- 쿼리 최적화 (EXPLAIN ANALYZE)
- 모니터링 (pg_stat_statements)

### [13. 스케일링 (Scaling)](./13-scaling/)
pgvector 확장 전략
- 수직 확장 (Vertical Scaling)
- 수평 확장 (Horizontal Scaling)
- 복제본 (Replicas)
- 샤딩 (Citus)

### [14. 실전 활용 사례 (Use Cases)](./14-use-cases/)
실제 프로젝트에서의 pgvector 활용
- **의미론적 검색 (Semantic Search)**
  - 임베딩 기반 문서 검색
  - 자연어 쿼리 처리
  - 다국어 검색 시스템
- **추천 시스템 (Recommendation System)**
  - 상품 추천
  - 콘텐츠 추천
  - 협업 필터링
- **이미지 유사도 검색 (Image Similarity Search)**
  - 이미지 임베딩
  - 역이미지 검색
  - 중복 이미지 탐지
- **RAG 시스템 (Retrieval-Augmented Generation)**
  - 문서 임베딩 및 저장
  - Context 검색
  - LLM과 통합

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

## 📊 학습 진행 상황

- [ ] 01. 설치
- [ ] 02. 시작하기
- [ ] 03. 벡터 타입
- [ ] 04. 벡터 저장
- [ ] 05. 벡터 쿼리
- [ ] 06. 인덱싱 ⭐
- [ ] 07. 반정밀도 벡터
- [ ] 08. 이진 벡터
- [ ] 09. 희소 벡터
- [ ] 10. 하이브리드 검색
- [ ] 11. 서브벡터
- [ ] 12. 성능 튜닝
- [ ] 13. 스케일링
- [ ] 14. 실전 활용 사례
- [ ] 15. FAQ & 참고 자료

## 🔗 주요 링크

- [pgvector GitHub](https://github.com/pgvector/pgvector)
- [PostgreSQL 공식 문서](https://www.postgresql.org/docs/)
- [pgvector 예제 모음](https://github.com/pgvector/pgvector-python/tree/master/examples)

## 📝 학습 방법

1. **읽기**: 각 섹션의 문서를 순서대로 읽기
2. **실습**: 코드를 직접 실행하고 결과 확인
3. **기록**: 중요한 내용과 막힌 부분을 문서에 추가
4. **실험**: 다양한 파라미터로 테스트하고 결과 비교

## 💡 TIP

- 모든 쿼리는 실제로 실행한 후 결과와 함께 기록
- 성능 관련 내용은 수치와 그래프로 정리
- 에러가 발생하면 해결 방법을 troubleshooting에 기록
- 주기적으로 배운 내용을 복습하고 정리

## 🚀 시작일

2024년 11월 14일

---

**Note**: 이 저장소는 개인 학습 목적으로 작성되었습니다.
