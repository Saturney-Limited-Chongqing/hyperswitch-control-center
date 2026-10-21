@react.component
let make = () => {
  let {merchantId} = React.useContext(UserInfoProvider.defaultContext).getCommonSessionDetails()
  let {userHasResourceAccess} = GroupACLHooks.useUserGroupACLHook()
  let destinations: array<(string, string, UserManagementTypes.resourceAccessType)> = [
    ("交易订单", "/payments", Payment),
    ("退款记录", "/refunds", Refund),
    ("客户资料", "/customers", Customer),
    ("收款分析", "/analytics-payments", Analytics),
  ]
  <section dataTestId="collection-home" className="flex flex-col gap-6">
    <div className="rounded-lg border border-blue-100 bg-blue-50 px-6 py-5">
      <h1 className="text-2xl font-semibold text-slate-800">
        {"商户收款概览"->React.string}
      </h1>
      <p className="mt-2 text-sm text-slate-600">
        {`当前商户 ${merchantId}。您可以查看收款和退款，支付渠道由平台统一管理。`->React.string}
      </p>
    </div>
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      {destinations
      ->Array.filter(((_, _, resource)) =>
        userHasResourceAccess(~resourceAccess=resource) == CommonAuthTypes.Access
      )
      ->Array.map(((title, path, _)) =>
        <button
          key=path
          className="rounded-lg border border-slate-200 bg-white p-5 text-left font-semibold text-slate-700 shadow-sm hover:border-blue-400 hover:text-blue-700"
          onClick={_ => GlobalVars.appendDashboardPath(~url=path)->RescriptReactRouter.push}>
          {title->React.string}
        </button>
      )
      ->React.array}
    </div>
  </section>
}
