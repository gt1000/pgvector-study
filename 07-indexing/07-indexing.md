# 📘 07. 인덱싱 (Indexing)

## 1) HNSW 인덱스
```sql
CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)
WITH (m=16, ef_construction=128);
```

## 2) IVFFlat 인덱스
```sql
CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops)
WITH (lists=100);
```

## 3) Partial Index
- 특정 조건만 인덱싱

## 4) Partitioning
- 대규모 테이블 성능 향상

## 5) 인덱스 빌드 성능 고려
- 메모리 크기
- 병렬 처리 옵션
