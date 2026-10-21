open UserManagementTypes

type navLink = {name: string, path: string, visible: bool}

@react.component
let make = (~onAdvanced) => {
  let {userHasResourceAccess} = GroupACLHooks.useUserGroupACLHook()
  let handleLogout = APIUtils.useHandleLogout(~eventName="user_signout_manual")
  let allowed = resource =>
    userHasResourceAccess(~resourceAccess=resource) == CommonAuthTypes.Access
  let (openMenu, setOpenMenu) = React.useState(_ => "")
  let menus: array<(string, array<navLink>)> = [
    (
      "收款订单",
      [
        {name: "订单管理", path: "/payments", visible: allowed(Payment)},
        {name: "退款管理", path: "/refunds", visible: allowed(Refund)},
        {name: "争议处理", path: "/disputes", visible: allowed(Dispute)},
        {name: "收款链接", path: "/payment-links", visible: allowed(Payment)},
        {name: "交易统计", path: "/analytics-payments", visible: allowed(Analytics)},
      ],
    ),
    (
      "商户管理",
      [
        {name: "商户列表", path: "/platform", visible: true},
        {name: "用户管理", path: "/users", visible: allowed(User)},
      ],
    ),
    (
      "支付接口",
      [
        {name: "支付通道", path: "/connectors", visible: allowed(Connector)},
        {name: "每日限额", path: "/platform/channel-limits", visible: true},
        {name: "通道路由", path: "/routing", visible: allowed(Routing)},
      ],
    ),
    (
      "系统设置",
      [
        {name: "API 密钥", path: "/developer-api-keys", visible: allowed(ApiKey)},
        {name: "回调通知", path: "/webhooks", visible: allowed(WebhookEvent)},
        {name: "支付设置", path: "/payment-settings", visible: allowed(Account)},
      ],
    ),
  ]
  let navigate = path => {
    setOpenMenu(_ => "")
    GlobalVars.appendDashboardPath(~url=path)->RescriptReactRouter.push
  }

  <nav className="rainbow-platform-topbar" ariaLabel="平台管理导航">
    <div className="rainbow-platform-brand"> {"支付管理中心"->React.string} </div>
    <button className="rainbow-platform-home" onClick={_ => navigate("/platform")}>
      {"平台首页"->React.string}
    </button>
    {menus
    ->Array.map(((name, links)) => {
      let visibleLinks = links->Array.filter(link => link.visible)
      visibleLinks->Array.length == 0
        ? React.null
        : <div key=name className="rainbow-platform-menu">
            <button
              ariaExpanded={openMenu == name}
              onClick={_ => setOpenMenu(current => current == name ? "" : name)}>
              {name->React.string}
              <span className="rainbow-platform-caret"> {"▾"->React.string} </span>
            </button>
            {openMenu == name
              ? <div className="rainbow-platform-dropdown">
                  {visibleLinks
                  ->Array.map(link =>
                    <button key=link.path onClick={_ => navigate(link.path)}>
                      {link.name->React.string}
                    </button>
                  )
                  ->React.array}
                </div>
              : React.null}
          </div>
    })
    ->React.array}
    <button className="rainbow-platform-advanced" onClick={_ => onAdvanced()}>
      {"高级功能"->React.string}
    </button>
    <button onClick={_ => navigate("/account-settings/profile")}>
      {"账户资料"->React.string}
    </button>
    <button onClick={_ => handleLogout()->ignore}> {"退出登录"->React.string} </button>
  </nav>
}
