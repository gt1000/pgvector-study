# 📘 10. 희소 벡터 (Sparse Vectors)

## 1) sparsevec 구조
- 0이 아닌 값 + 인덱스만 저장

## 2) sparsevec 삽입
```sql
INSERT INTO items VALUES ('{1:0.5, 5:1.0}'::sparsevec);
```

## 3) sparsevec 검색
- 추천 엔진에 최적
