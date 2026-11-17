FROM 172.30.10.185:15000/common/python:3.13-slim

ENV APP_HOME=/dianyi/app/wren-sidecar \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    WREN_PORT=8090

WORKDIR $APP_HOME

COPY docker/wren-sidecar/start.sh ./start.sh

ARG WREN_VERSION=0.18.0
ARG PYPI_INDEX_URL=https://pypi.org/simple
RUN pip install --no-cache-dir --index-url "${PYPI_INDEX_URL}" \
      "wrenai[mcp,postgres,clickhouse,trino]==${WREN_VERSION}" \
    && chmod 755 ./start.sh

EXPOSE 8090
CMD ["./start.sh"]
