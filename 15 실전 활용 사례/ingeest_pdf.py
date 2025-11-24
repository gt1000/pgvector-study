import requests
import psycopg2
from pypdf import PdfReader

EMBED_URL = "http://localhost:8000/embed-batch"

DB = dict(
    host="localhost",
    port=35432,
    dbname="study",
    user="study_postgres",
    password="study_postgres",
)

def read_pdf_chunks(path, chunk_size=500):
    reader = PdfReader(path)
    texts = []
    for page in reader.pages:
        tx = page.extract_text() or ""
        texts.append(tx.replace("\n", " "))
    full = " ".join(texts)

    chunks, buf = [], []
    for word in full.split():
        buf.append(word)
        if len(" ".join(buf)) >= chunk_size:
            chunks.append(" ".join(buf))
            buf = []
    if buf:
        chunks.append(" ".join(buf))
    return chunks

def embed_texts(texts):
    r = requests.post(EMBED_URL, json={"texts": texts})
    return r.json()["embeddings"]

def save_db(chunks, embeddings):
    conn = psycopg2.connect(**DB)
    cur = conn.cursor()
    for t, e in zip(chunks, embeddings):
        cur.execute(
            """
            INSERT INTO research_docs (chunk_text, embedding)
            VALUES (%s, %s::vector)
            """,
            (t, e),
        )
    conn.commit()
    cur.close()
    conn.close()

if __name__ == "__main__":
    chunks = read_pdf_chunks("fish_growth.pdf")
    embs = embed_texts(chunks)
    save_db(chunks, embs)
