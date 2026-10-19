@react.component
let make = () => {
  let {getResolvedUserInfo, getCommonSessionDetails} = React.useContext(
    UserInfoProvider.defaultContext,
  )
  let {roleId} = getResolvedUserInfo()
  let {merchantId} = getCommonSessionDetails()
  let title = DashboardAccess.isCollectionRole(roleId)
    ? "Merchant dashboard"
    : DashboardAccess.isPlatformRole(roleId)
    ? "Platform administration"
    : "Control Center"

  <div dataTestId="dashboard-identity" className="flex flex-col gap-1 border-b pb-3">
    <span className="text-sm font-semibold"> {title->React.string} </span>
    <span className="text-xs text-nd_gray-500">
      {`Current merchant: ${merchantId}`->React.string}
    </span>
  </div>
}
