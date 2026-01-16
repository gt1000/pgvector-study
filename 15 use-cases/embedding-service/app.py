from fastapi import FastAPI
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer

app = FastAPI()

model = SentenceTransformer("jhgan/ko-sbert-sts")

class EmbedRequest(BaseModel):
    text: str

class EmbedBatchRequest(BaseModel):
    texts: list[str]

@app.post("/embed")
def embed(req: EmbedRequest):
    vec = model.encode(req.text)
    return {"embedding": vec.tolist()}

@app.post("/embed-batch")
def embed_batch(req: EmbedBatchRequest):
    vectors = model.encode(req.texts)
    return {"embeddings": [v.tolist() for v in vectors]}
