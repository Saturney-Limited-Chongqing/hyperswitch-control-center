#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

usage() {
  cat <<'EOF'
用法: ./build.sh [--dev]

无参数    构建 Control Center 的生产版本（输出到 dist/）。
--dev     启动 ReScript 监听和网页开发服务，供手动调试。

调试时可设置 PORT（默认 9000）、HOST（默认 127.0.0.1）和
API_PROXY_TARGET（默认 http://localhost:8080）。远端访问示例：
  HOST=0.0.0.0 PORT=19000 API_PROXY_TARGET=http://127.0.0.1:8080 ./build.sh --dev

脚本不会执行 git reset、git clean、自动格式化或覆盖配置文件。
EOF
}

if [[ "${1:-}" == -h || "${1:-}" == --help ]]; then
  usage
  exit 0
fi

if [[ ! -x node_modules/.bin/rescript || ! -x node_modules/.bin/webpack ]]; then
  echo '缺少前端依赖。请先在本目录执行 npm ci。' >&2
  exit 1
fi

case "${1:-}" in
  '')
    npm run build:prod
    ;;
  --dev)
    npm run re:build
    node_modules/.bin/rescript -w &
    watcher_pid=$!
    cleanup() {
      kill "$watcher_pid" 2>/dev/null || true
      wait "$watcher_pid" 2>/dev/null || true
    }
    trap cleanup EXIT INT TERM
    echo "调试地址: http://${HOST:-127.0.0.1}:${PORT:-9000}"
    npm start -- --host "${HOST:-127.0.0.1}"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
