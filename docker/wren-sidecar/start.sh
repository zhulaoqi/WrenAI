#!/bin/sh
set -eu

APP_HOME=/dianyi/app/wren-sidecar
cd "$APP_HOME"

HOSTIP="${HOSTIP:-local}"
LOGS_DIR="/docker/log/${HOSTIP}"
mkdir -p "$LOGS_DIR" /dianyi
ln -sfn "$LOGS_DIR" /dianyi/log

case "${PROFILE:-test-ali}" in
  prod|PRO|pro|prod-ali) PROFILE=prod-ali ;;
  *) PROFILE=test-ali ;;
esac
export PROFILE

PORT="${WREN_PORT:-8090}"
HOST="${WREN_HOST:-0.0.0.0}"
PROJECT="${WREN_PROJECT:-/dianyi/app/wren-sidecar/project}"

banner="/dianyi/log/wren-sidecar.banner"
{
  echo "================================"
  echo " wren-sidecar"
  echo " profile: ${PROFILE}"
  echo " project: ${PROJECT}"
  echo " listen: ${HOST}:${PORT}"
  echo " mcp: /mcp"
  echo "================================"
} | tee "$banner"

if [ ! -f "${PROJECT}/target/mdl.json" ]; then
  echo "wren-sidecar: 找不到 ${PROJECT}/target/mdl.json。请放入模块 B 产出的 MDL 项目（需要 target/mdl.json），或在该目录执行 wren context build 后再启动。" | tee -a "$banner" >&2
  exit 1
fi

if [ -n "${WREN_PROFILE:-}" ]; then
  exec wren serve mcp --transport http --host "$HOST" --port "$PORT" --project "$PROJECT" --profile "$WREN_PROFILE" --quiet
fi
exec wren serve mcp --transport http --host "$HOST" --port "$PORT" --project "$PROJECT" --quiet
