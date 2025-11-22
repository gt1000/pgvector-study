-- 스키마 생성 및 권한 설정

-- PostGIS 스키마
CREATE SCHEMA IF NOT EXISTS gis;

-- pgvector 스키마
CREATE SCHEMA IF NOT EXISTS vector;
-- pgvector extension 자동 생성
CREATE EXTENSION IF NOT EXISTS vector SCHEMA vector;

-- ========================================
-- 권한 설정 (간소화)
-- ========================================

-- gis 스키마 권한
GRANT ALL PRIVILEGES ON SCHEMA gis TO study_postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA gis GRANT ALL PRIVILEGES ON TABLES TO study_postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA gis GRANT ALL PRIVILEGES ON SEQUENCES TO study_postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA gis GRANT ALL PRIVILEGES ON FUNCTIONS TO study_postgres;

-- vector 스키마 권한
GRANT ALL PRIVILEGES ON SCHEMA vector TO study_postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA vector GRANT ALL PRIVILEGES ON TABLES TO study_postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA vector GRANT ALL PRIVILEGES ON SEQUENCES TO study_postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA vector GRANT ALL PRIVILEGES ON FUNCTIONS TO study_postgres;

-- search_path 설정(테이블 이름만 쓸 때 어느 스키마에서 찾을지 순서를 정하는 것)
ALTER DATABASE study SET search_path TO public, gis, vector;

COMMIT;