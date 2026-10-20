@react.component
let make = () => {
  let merchants = Recoil.useRecoilValueFromAtom(HyperswitchAtom.merchantListAtom)
  let {merchantId} = React.useContext(UserInfoProvider.defaultContext).getCommonSessionDetails()
  let {setActiveProductValue} = React.useContext(ProductSelectionProvider.defaultContext)
  let switchMerchant = OMPSwitchHooks.useInternalSwitch(~setActiveProductValue)
  let (switching, setSwitching) = React.useState(_ => false)
  let showToast = ToastAdapter.useShowToast()

  let manageMerchant = async (merchant: OMPSwitchTypes.ompListTypes) => {
    setSwitching(_ => true)
    try {
      let _ = await switchMerchant(
        ~expectedMerchantId=Some(merchant.id),
        ~version=merchant.version->Option.getOr(UserInfoTypes.V1),
      )
      GlobalVars.appendDashboardPath(~url="/home")->RescriptReactRouter.push
    } catch {
    | _ => showToast(~message="Unable to switch merchant", ~toastType=ToastError)
    }
    setSwitching(_ => false)
  }

  <section dataTestId="platform-management" className="flex flex-col gap-5">
    <h1 className="text-2xl font-semibold"> {"Merchant management"->React.string} </h1>
    <p className="text-nd_gray-500">
      {"Select an authorized merchant to manage its channels, routing and transactions."->React.string}
    </p>
    <div className="border rounded-lg divide-y">
      {merchants
      ->Array.map(merchant =>
        <div key={merchant.id} className="flex items-center justify-between p-4 gap-4">
          <div className="flex flex-col gap-1">
            <span className="font-semibold"> {merchant.name->React.string} </span>
            <span className="text-sm text-nd_gray-500"> {merchant.id->React.string} </span>
          </div>
          <button
            disabled=switching
            className="border rounded px-4 py-2 disabled:opacity-50"
            onClick={_ => manageMerchant(merchant)->ignore}>
            {(
              merchant.id == merchantId ? "Manage current merchant" : "Manage merchant"
            )->React.string}
          </button>
        </div>
      )
      ->React.array}
    </div>
    <ChannelDailyLimits />
  </section>
}
