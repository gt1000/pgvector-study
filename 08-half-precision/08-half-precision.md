# 📘 08. 반정밀도 벡터 (Half-Precision)

## 1) halfvec 타입
- float16 기반
- 저장 공간 절약

## 2) halfvec 인덱싱
```sql
CREATE INDEX ON items USING hnsw (embedding halfvec_l2_ops);
```

## 3) halfvec 검색
- 메모리 효율 높은 쿼리
