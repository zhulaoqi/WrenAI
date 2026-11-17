#!/bin/bash
cd "$(dirname "$0")/../.."
echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') build wren-sidecar"
python3 -c 'import sys; assert sys.version_info >= (3, 11), sys.version'
if [ $? -ne 0 ]; then
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') Compilation failed, request the developer to confirm it."
  exit 1
fi
echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') wren-sidecar image installs wrenai from PyPI during docker build"
