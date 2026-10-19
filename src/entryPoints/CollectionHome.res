@react.component
let make = () => {
  let {merchantId} = React.useContext(UserInfoProvider.defaultContext).getCommonSessionDetails()
  let {userHasResourceAccess} = GroupACLHooks.useUserGroupACLHook()
  let destinations: array<(string, string, UserManagementTypes.resourceAccessType)> = [
    ("Payments", "/payments", Payment),
    ("Refunds", "/refunds", Refund),
    ("Customers", "/customers", Customer),
    ("Payment analytics", "/analytics-payments", Analytics),
  ]
  <section dataTestId="collection-home" className="flex flex-col gap-5">
    <h1 className="text-2xl font-semibold"> {"Your collections"->React.string} </h1>
    <p className="text-nd_gray-500">
      {`Manage payments and review activity for ${merchantId}. Payment channels are managed by your platform.`->React.string}
    </p>
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      {destinations
      ->Array.filter(((_, _, resource)) =>
        userHasResourceAccess(~resourceAccess=resource) == CommonAuthTypes.Access
      )
      ->Array.map(((title, path, _)) =>
        <button
          key=path
          className="border rounded-lg p-5 text-left font-semibold hover:bg-nd_gray-100"
          onClick={_ => GlobalVars.appendDashboardPath(~url=path)->RescriptReactRouter.push}>
          {title->React.string}
        </button>
      )
      ->React.array}
    </div>
  </section>
}
