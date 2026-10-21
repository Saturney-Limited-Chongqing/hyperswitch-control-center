@react.component
let make = () => {
  let {getResolvedUserInfo, getCommonSessionDetails} = React.useContext(
    UserInfoProvider.defaultContext,
  )
  let {roleId} = getResolvedUserInfo()
  let {merchantId} = getCommonSessionDetails()
  let title = DashboardAccess.isCollectionRole(roleId)
    ? "商户中心"
    : DashboardAccess.isPlatformRole(roleId)
    ? "平台管理"
    : "Control Center"

  <div
    dataTestId="dashboard-identity"
    className="flex flex-col gap-1 rounded-lg border border-slate-200 bg-white px-5 py-4 shadow-sm">
    <span className="text-lg font-semibold text-slate-800"> {title->React.string} </span>
    <span className="text-sm text-slate-500"> {`当前商户：${merchantId}`->React.string} </span>
  </div>
}
