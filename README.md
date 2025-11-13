# pgvector Study

PostgreSQL의 벡터 유사도 검색 확장 프로그램인 pgvector를 체계적으로 학습하고 기록하는 저장소입니다.

## 📚 학습 목표

- pgvector의 핵심 개념과 사용법 이해
- HNSW와 IVFFlat 인덱스의 원리와 차이점 파악
- 벡터 검색 성능 최적화 방법 습득
- 실제 프로덕션 환경에서의 활용 능력 배양

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