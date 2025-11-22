FROM postgis/postgis:17-3.5

# pgvector 설치
RUN apt-get update && \
    apt-get install -y build-essential git postgresql-server-dev-17 && \
    cd /tmp && \
    git clone --branch v0.8.1 https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make && make install && \
    cd / && rm -rf /tmp/pgvector && \
    apt-get remove -y build-essential git postgresql-server-dev-17 && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*