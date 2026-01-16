import requests
import psycopg2

EMBED_URL = "http://localhost:8000/embed"
LLM_URL = "http://localhost:8001/answer"

DB = dict(
    host="localhost",
    port=35432,
    dbname="study",
    user="study_postgres",
    password="study_postgres",
)

def embed_query(text):
    r = requests.post(EMBED_URL, json={"text": text})
    return r.json()["embedding"]

def search_chunks(emb, k=5):
    conn = psycopg2.connect(**DB)
    cur = conn.cursor()
    cur.execute(
        """
        SELECT chunk_text
        FROM research_docs
        ORDER BY embedding <-> %s::vector
        LIMIT %s
        """,
        (emb, k),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [r[0] for r in rows]

def ask_llm(question, contexts):
    r = requests.post(LLM_URL, json={"question": question, "contexts": contexts})
    return r.json()["answer"]

if __name__ == "__main__":
    question = "수온 상승이 어류 성장과 사료 효율에 미치는 영향은?"
    emb = embed_query(question)
    ctx = search_chunks(emb)

    print("=== 관련 문단 ===")
    for c in ctx:
        print(c[:200], "...\n")

    print("=== 최종 답변 ===")
    print(ask_llm(question, ctx))
