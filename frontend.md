# 前端交接：中文平台/商户中台

更新基线：Control Center `7e230e2`（2026-10-21）。本仓库是独立前端仓库；对应后端仓库的 `backend.md` 与 `docs/` 记录服务端协议。本文按当前代码说明已实现内容和待办，不能把导航可见性当作授权依据。

## 目标与边界

界面参考彩虹易支付后台的信息架构和 Bootstrap 式简洁布局，使用简体中文，保留 Hyperswitch 的现有功能及支付连接器架构。平台管理员管理商户、渠道、路由和限额；收款商户只进入自己商户的交易工作区。彩虹的余额、结算、提现、分润等没有完整后端语义，当前不展示虚构数据。概念映射见 `docs/rainbow-ui-mapping.md`。

## 已完成的页面与行为

| 范围 | 当前实现 | 主要代码 |
| --- | --- | --- |
| 平台首页 | `/platform` 展示有权管理的商户、进入商户、渠道/路由/订单入口和限额面板 | `src/entryPoints/PlatformManagement.res` |
| 商户首页 | `/home` 展示当前商户 ID 和订单、退款、客户、分析入口 | `src/entryPoints/CollectionHome.res` |
| 平台导航 | 中文「收款订单／商户管理／支付接口／系统设置」；高级功能仍可进入原上游页面 | `src/entryPoints/RainbowPlatformNav.res` |
| 门户外观 | 中文入口、商户身份提示、Bootstrap 风格样式和双侧栏入口 | `src/entryPoints/DashboardPortal.res`、`rainbow-portal.css`、`SidebarHooks.res`、`screens/Sidebar/Sidebar.res` |
| 访问控制 | `tenant_admin`/`internal_admin` 可进平台页；`collection_merchant_admin`/`collection_merchant_view_only` 只允许收款工作区路径；直接输入管理 URL 会拦截 | `src/entryPoints/DashboardAccess.res`、`HyperSwitchApp.res`、`HyperswitchAppHelper.res` |
| 商户切换 | 平台用户沿用授权商户列表和原有切换 API；切换时清理旧商户视图/忽略过期异步结果 | `PlatformManagement.res`、`OMPSwitch/*`、`hooks/DashboardSessionGuard.res` |
| 每日限额 | `/platform/channel-limits` 读取/保存商户渠道的每日额度和共享额度池，输入大单位，提交最小货币单位 | `src/entryPoints/ChannelDailyLimits.res` |
| 登录 | 在原有登录选择器中加入 Rauthy 与 Logto；Logto 回调 `/redirect/oidc/logto`，Rauthy 回调 `/redirect/oidc/rauthy` | `AuthModule/AuthWrapper.res`、`PreLoginModule/AuthSelect.res`、`SSOAuth/*` |

订单、退款、客户、API 密钥、回调、支付渠道和路由页继续复用上游组件；与本次平台/商户权限相关的详情、列表、状态和数据刷新适配分散在 `src/screens/Transaction*`、`Connectors/*`、`Processors/*`、`OrchestrationHooks/*`、`hooks/AuthHooks.res`。不要仅凭改了导航就认定相应页面已完全重写或全面中文化。

## 角色、登录和接口契约

后端认证和 RBAC 是最终裁决。前端通过当前用户的 `role_id`、当前商户、资源权限决定入口与显示；商户前端不能提供商户 ID 来突破后端认证上下文。平台用户看到的是后端返回的有权商户列表，切换后页面需以新的商户上下文重新取数。不要把平台管理员 API Key、OIDC client secret 或商户原始支付密钥放入浏览器。

Logto 是当前推荐的角色分配入口：全局 `tenant_admin` 给平台用户；组织内 `collection_merchant_admin` 或 `collection_merchant_view_only` 给商户用户。用户的 Logto `sub`、组织 ID、角色和本地 Hyperswitch 身份由后端显式绑定。前端只处理授权码跳转与普通 Hyperswitch 后台会话，不能凭 Logto 邮件地址自行认领商户。进入方式为 `/?auth_id=<后端认证方式的 auth_id>`。已有 Rauthy 路径继续支持，但其角色取自本地绑定，不按 Rauthy 角色授予权限。详细配置见后端 `docs/logto_rbac.md`、`docs/rauthy_sso.md`。

限额面板调用 `GET /api/configs/channel-limits` 和 `POST /api/configs/channel-limits`，提交字段为 `merchant_id`、`merchant_connector_id`、`pool_id`、`currency`、`timezone`、整数最小单位 `daily_limit`、`enabled`。列表提供 `used` 等用量。手工对账入口 `POST /api/configs/channel-limits/reconcile` 目前只有服务端/API/CLI，没有前端操作页。退款页使用 Hyperswitch 原生退款 API；彩虹兼容入口属于独立服务，不在前端直接调用。完整语义见后端 `docs/channel_limits_and_epay_v2.md`。

## 本地构建与手动调试

在本仓库执行一次 `npm ci`，随后 `./build.sh` 生成 `dist/`；`./test.sh` 编译 ReScript 并运行访问策略测试。`./build.sh --dev` 启动持续编译及开发服务。远端调试示例：

```sh
HOST=0.0.0.0 PORT=19001 API_PROXY_TARGET=http://127.0.0.1:18082 \
  default__endpoints__api_url=http://10.100.100.22:19001/api ./build.sh --dev
```

`API_PROXY_TARGET` 是服务器能访问的后端地址；`default__endpoints__api_url` 必须是**浏览器能访问**的前端 `/api` 地址，不能误填远端服务器的 localhost。后端 `[user].base_url` 必须与浏览器访问的前端 origin 一致。以上 IP/端口只代表当前 ZeroTier 调试环境；生产环境改为 HTTPS 域名。详见 `docs/manual-debug.md`。

浏览器回归需预先准备专用测试夹具并启动网页：

```sh
COLLECTION_TEST_FIXTURES=/private/path/fixtures.json \
COLLECTION_TEST_UI_URL=http://10.100.100.22:19001 ./test.sh --browser
```

`tests/dashboard-access.test.mjs` 检查访问规则；`playwright-tests/collection/isolation.spec.ts` 检查双商户浏览器隔离；`playwright-tests/collection/rauthy.spec.ts` 检查 Rauthy 登录。真实 Logto 联调也应覆盖平台和两个独立组织商户，不能只靠前端单测。测试夹具、邮箱密码和令牌不得提交。

## 新增支付 Connector 时前端怎么接

Connector 的 HTTP 协议、签名、退款和 webhook 实现在后端 `crates/hyperswitch_connectors`；前端只负责平台管理员配置渠道账户和查看状态。后端 `backend.md` 的“以后新增支付 Connector”与仓库根目录 `add_connector.md` 是开发入口。不要把渠道私钥、客户端密钥或后台管理员 Key 写入静态资源或浏览器环境变量。

接入一个新渠道时，先确认后端已注册连接器枚举、可用支付方式、认证字段和环境配置。随后检查本仓库 `src/screens/Connectors/ConnectorTypes.res`、`ConnectorUtils.res`、连接器列表/配置表单及 `public/hyperswitch/assets/Gateway/` 图标，让平台管理员能识别、创建并查看该渠道账户；若路由编辑依赖 `euclid_wasm`，按照后端 `add_connector.md` 的说明重新构建并核对 WASM 产物。上游指南里的旧图标路径与当前仓库不同，以当前目录为准。商户角色不能因此获得 `/connectors`、`/routing` 或 `/platform/channel-limits` 的访问权限。完成后运行 `./test.sh`、平台创建/编辑渠道的浏览器测试，以及商户直接访问管理 URL 的拒绝测试。新渠道是否真正可收款、退款和处理回调，必须由后端沙箱联调验证，不能只看前端列表中出现图标。

## 接手时优先处理

1. 逐页统一中文文案、表格密度、表单和错误提示。平台首页后的上游高级页面仍有英语，当前并非“全面中文化”。
2. 对订单、退款、支付渠道、路由、API 密钥、回调等现有页面分别做平台/商户体验检查；不要改变支付连接器协议。
3. 为额度池、时区、金额精度增加更明确的输入校验和错误信息；需要手工解除不确定占额时设计独立的对账流程，而非自动释放。
4. 每次上游合并后检查 `DashboardAccess`、两种侧栏、登录回调、商户切换和 `/api` 配置；运行 `./test.sh` 及双商户浏览器回归。

当前远端测试入口为 `http://10.100.100.22:19001/`，Logto 控制台为 `http://10.100.100.22:18093/`，仅用于受信任的 ZeroTier 调试网络。接手人应向管理员领取 `auth_id` 和临时测试账号，不在本文件记录口令。
