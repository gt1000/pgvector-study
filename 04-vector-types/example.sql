-- DDL: 테이블 생성
CREATE TABLE test1 (
                       id BIGSERIAL PRIMARY KEY,
                       content TEXT,
                       embedding vector(2)
);

-- DML: 데이터 삽입
INSERT INTO test1 (content, embedding)
VALUES ('테스트 데이터', '[0.123456789012, -0.987654321098]');

-- 결과 확인
SELECT id, content, embedding FROM test1;

-- halfvec 예제
CREATE TABLE test2 (
                       id BIGSERIAL PRIMARY KEY,
                       content TEXT,
                       embedding halfvec(1536)
);

CREATE TABLE test3 (
                             id BIGSERIAL PRIMARY KEY,
                             content TEXT,
                             embedding_binary bit(2),
                             embedding_full vector(2)
);

-- 데이터 삽입
INSERT INTO test3 (content, embedding_binary, embedding_full)
VALUES (
           '테스트 문서 1',
           B'10',
           '[0.5, -0.3]'
       ),
       (
           '테스트 문서 2',
           B'01',
           '[-0.2, 0.7]'
       ),
       (
           '테스트 문서 3',
           B'11',
           '[0.8, 0.6]'
       );

WITH candidates AS (
    SELECT id
    FROM test3
    ORDER BY embedding_binary <~> B'10'
    LIMIT 2
    )
SELECT t.id, t.content, t.embedding_full <=> '[0.4, -0.2]' AS distance
FROM test3 t
    JOIN candidates c ON t.id = c.id
ORDER BY distance
    LIMIT 1;


CREATE TABLE test4 (
                       user_id BIGINT PRIMARY KEY,
                       item_vector sparsevec(10000)  -- 10000개 상품 중 구매한 것만 저장
);

INSERT INTO test4 (user_id, item_vector)
VALUES (1, '{1:0.8,5:0.6,127:0.9,523:0.7}/10000');


CREATE TABLE test5 (
                       product_id BIGSERIAL PRIMARY KEY,
                       product_name TEXT,
                       embedding vector(2)
);

INSERT INTO test5 (product_name, embedding)
VALUES
    ('상품 A', '[0.8, 0.6]'),
    ('상품 B', '[0.3, 0.9]'),
    ('상품 C', '[-0.5, 0.7]');


-- float32 → halfvec 변환
CREATE TABLE test6 AS
SELECT id, content, embedding::halfvec(2) as embedding
FROM test1;

-- 인덱스 재생성
CREATE INDEX ON test6 USING hnsw (embedding halfvec_cosine_ops);