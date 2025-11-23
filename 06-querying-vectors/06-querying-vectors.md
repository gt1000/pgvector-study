# 📘 06. 벡터 쿼리 (Querying Vectors)

## 1) 거리 기반 검색
```sql
ORDER BY embedding <-> '[1,0,0]' LIMIT 5;
```

## 2) Top-K 검색
- 최근접 이웃 방식

## 3) 필터링 + 벡터 검색
```sql
WHERE category='news' ORDER BY embedding <-> :vec LIMIT 10;
```

## 4) Exact vs Approximate
- 정확도 vs 속도 비교

## 5) Re-ranking
- coarse → fine 방식
