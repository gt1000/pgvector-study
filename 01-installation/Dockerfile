FROM postgis/postgis:18-3.6

# ==========================================
# 1. 한국어 로케일 설치 (로케일 미존재 문제 해결)
# ==========================================
RUN apt-get update && \
    apt-get install -y locales && \
    sed -i 's/# ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen ko_KR.UTF-8 && \
    update-locale LANG=ko_KR.UTF-8 LC_ALL=ko_KR.UTF-8

# 기본 로케일 환경변수 설정 (정렬은 C로 composer에서 override 예정)
ENV LANG=ko_KR.UTF-8 \
    LC_ALL=ko_KR.UTF-8

# ==========================================
# 2. pgvector 빌드 도구 설치
# ==========================================
RUN apt-get install -y build-essential git postgresql-server-dev-18

# ==========================================
# 3. pgvector 소스 빌드 & 설치
# ==========================================
RUN git clone --branch v0.8.1 https://github.com/pgvector/pgvector.git /tmp/pgvector && \
    cd /tmp/pgvector && \
    make && make install && \
    rm -rf /tmp/pgvector

# ==========================================
# 4. 빌드 관련 패키지 제거 (이미지 경량화)
# ==========================================
RUN apt-get remove -y build-essential git postgresql-server-dev-18 && \
    apt-get autoremove -y
