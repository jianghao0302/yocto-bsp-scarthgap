#!/usr/bin/env bash

# ====== 日志/颜色 ======
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()
{
    printf "${GREEN}[INFO] %s${NC}\n" "$*";
}

warn()
{
    printf "${YELLOW}[WARN] %s${NC}\n" "$*";
}

err()
{
    printf "${RED}[ERROR] %s${NC}\n" "$*" >&2;
}

die()
{
    err "$*";
    exit 1;
}