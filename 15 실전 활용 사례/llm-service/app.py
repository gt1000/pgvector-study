from fastapi import FastAPI
from pydantic import BaseModel
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

app = FastAPI()

MODEL_NAME = "google/flan-t5-base"

tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_NAME)

class AnswerRequest(BaseModel):
    question: str
    contexts: list[str]

@app.post("/answer")
def answer(req: AnswerRequest):
    context_text = "\n\n".join(req.contexts)

    prompt = (
        "다음은 논문에서 가져온 내용입니다. 이를 기반으로 한국어로 답변해 주세요.\n\n"
        f"[논문 내용]\n{context_text}\n\n"
        f"[질문]\n{req.question}\n\n"
        "위 내용을 근거로 한국어로 핵심만 요약해 답변해 주세요."
    )

    inputs = tokenizer(prompt, return_tensors="pt", max_length=1024, truncation=True)
    outputs = model.generate(**inputs, max_new_tokens=256)
    answer = tokenizer.decode(outputs[0], skip_special_tokens=True)

    return {"answer": answer}
