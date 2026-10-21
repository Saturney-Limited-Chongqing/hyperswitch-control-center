# 手动构建与调试 Control Center

以下命令均在 `hyperswitch-control-center` 仓库目录执行。先运行一次 `npm ci` 安装锁定版本的依赖；之后两个脚本不会安装依赖、修改 Git 状态或自动格式化源码。

```sh
./build.sh            # 生产构建，结果在 dist/
./test.sh             # 编译并检查后台权限隔离
```

手动看网页时，在运行着后端的机器上启动开发服务：

```sh
HOST=0.0.0.0 PORT=19000 API_PROXY_TARGET=http://127.0.0.1:8080 ./build.sh --dev
```

然后从获准访问该机器的设备打开 `http://机器地址:19000`。`--dev` 会持续编译 `.res` 文件并刷新网页；按 Ctrl-C 停止。只在受信任的内网使用 `HOST=0.0.0.0`，本机调试可省略 `HOST`。

需要复测双商户隔离时，保持网页服务运行，另开一个终端：

```sh
COLLECTION_TEST_FIXTURES=/绝对路径/fixtures.json \
COLLECTION_TEST_UI_URL=http://127.0.0.1:19000 \
./test.sh --browser
```

浏览器测试需要预先创建的专用测试用户和数据。脚本不会创建测试用户；没有设置测试数据或网址时会直接报错。`./build.sh --help` 和 `./test.sh --help` 可查看参数。

脚本会优先使用系统里的 `google-chrome`。如果机器上的 Chrome 在别的位置，可设置 `PLAYWRIGHT_CHROME_EXECUTABLE=/绝对路径/chrome`；若没有系统 Chrome，则需要先执行 `npx playwright install chromium`。
