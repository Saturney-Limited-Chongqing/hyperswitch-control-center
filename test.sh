#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

usage() {
  cat <<'EOF'
用法: ./test.sh [--browser]

无参数    编译 ReScript 并运行后台权限隔离测试。
--browser  再运行双商户浏览器联调；须先启动调试服务并设置：
             COLLECTION_TEST_FIXTURES=/绝对路径/fixtures.json
             COLLECTION_TEST_UI_URL=http://127.0.0.1:19000

浏览器测试只应使用专门的测试用户和测试数据。
EOF
}

case "${1:-}" in
  ''|--browser) ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

if [[ ! -x node_modules/.bin/rescript ]]; then
  echo '缺少前端依赖。请先在本目录执行 npm ci。' >&2
  exit 1
fi

npm run re:build
npm run test:dashboard-access

if [[ "${1:-}" == --browser ]]; then
  if [[ ! -x node_modules/.bin/playwright ]]; then
    echo '缺少 Playwright。请先在本目录执行 npm ci。' >&2
    exit 1
  fi
  if [[ -z "${COLLECTION_TEST_FIXTURES:-}" || ! -f "${COLLECTION_TEST_FIXTURES:-}" ]]; then
    echo '请设置 COLLECTION_TEST_FIXTURES，指向已有的双商户测试数据文件。' >&2
    exit 1
  fi
  if [[ -z "${COLLECTION_TEST_UI_URL:-}" ]]; then
    echo '请设置 COLLECTION_TEST_UI_URL，指向正在运行的调试界面。' >&2
    exit 1
  fi
  if [[ -z "${PLAYWRIGHT_CHROME_EXECUTABLE:-}" ]] && command -v google-chrome >/dev/null 2>&1; then
    export PLAYWRIGHT_CHROME_EXECUTABLE="$(command -v google-chrome)"
  fi
  npx playwright test --config playwright.collection.config.ts playwright-tests/collection/isolation.spec.ts
fi
