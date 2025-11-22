#!/bin/bash
set -e  # 오류 발생 시 스크립트 중단

# 1. 스키마 생성
echo "=== Creating schemas ==="
for file in /database/schema/*.sql
do
  echo "Executing: ${file}"
  psql -U study_postgres -d study -a -f "${file}"
done

# 2. DDL 실행
echo "=== Executing DDL files ==="
for file in /database/ddl/*.sql
do
  echo "Executing: ${file}"
  psql -U study_postgres -d study -a -f "${file}"
done

echo "=== Database initialization completed ==="