# 📘 04. 벡터 타입 (Vector Types)

## 1) vector (float32)
- pgvector의 기본 타입
- 고정 길이 float32 벡터
- 최대 2000차원

## 2) halfvec (float16)
- 메모리 절약 (약 50%)
- float16 기반
- 약간의 정확도 손실

## 3) bit (Binary Vector)
- 이진 양자화 벡터
- 저장 공간 매우 작음
- 대규모 검색 시스템 최적화

## 4) sparsevec (Sparse Vector)
- 0이 아닌 요소만 저장
- 추천 시스템/NLP 희소 벡터에 적합

## 5) 거리 함수 연산자 비교
- `<->` : L2 Distance
- `<=>` : Cosine Distance
- `<#>` : Inner Product
