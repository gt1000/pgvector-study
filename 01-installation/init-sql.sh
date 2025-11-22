#!/bin/bash
set -e

echo "========================================="
echo "Database Initialization Started"
echo "========================================="

# 1. 스키마 생성
echo ""
echo ">>> Step 1: Creating schemas"
for file in /database/schema/*.sql; do
  if [ -f "$file" ]; then
    echo "Executing: $file"
    psql -U study_postgres -d study -a -f "$file"
  fi
done

# 2. DDL 실행
echo ""
echo ">>> Step 2: Executing DDL files"
for file in /database/ddl/*.sql; do
  if [ -f "$file" ]; then
    echo "Executing: $file"
    psql -U study_postgres -d study -a -f "$file"
  fi
done

echo ""
echo "========================================="
echo "Database Initialization Completed"
echo "========================================="