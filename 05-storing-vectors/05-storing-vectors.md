# 📘 05. 벡터 저장 (Storing Vectors)

## 1) Insert / Bulk Insert
```sql
INSERT INTO items (embedding) VALUES ('[1,2,3]');
```

## 2) Update / Upsert
```sql
UPDATE items SET embedding='[3,2,1]' WHERE id=1;
```

## 3) Delete
```sql
DELETE FROM items WHERE id=1;
```

## 4) 메타데이터 설계
- JSONB 활용
- 태그, 생성일, 출처 등 저장

## 5) JSON + vector 구조
- RAG 시스템에 최적화된 구조
