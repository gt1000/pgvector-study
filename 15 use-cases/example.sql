CREATE TABLE IF NOT EXISTS research_docs (
                                             id          bigserial PRIMARY KEY,
                                             chunk_text  text NOT NULL,
                                             embedding   vector(768) NOT NULL,
    meta        jsonb,
    created_at  timestamptz DEFAULT now()
    );
