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
    | _ => showToast(~message="切换商户失败，请检查访问权限", ~toastType=ToastError)
    }
    setSwitching(_ => false)
  }

  <section dataTestId="platform-management" className="flex flex-col gap-6">
    <div className="rounded-lg border border-blue-100 bg-blue-50 px-6 py-5">
      <h1 className="text-2xl font-semibold text-slate-800"> {"平台总览"->React.string} </h1>
      <p className="mt-2 text-sm text-slate-600">
        {"统一管理商户、支付渠道和每日限额。选择商户后可查看其交易与路由配置。"->React.string}
      </p>
    </div>
    <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
      {[
        ("支付渠道", "/connectors"),
        ("路由规则", "/routing"),
        ("交易订单", "/payments"),
      ]
      ->Array.map(((label, path)) =>
        <button
          key=path
          className="rounded-lg border border-slate-200 bg-white p-5 text-left font-semibold text-slate-700 shadow-sm hover:border-blue-400 hover:text-blue-700"
          onClick={_ => GlobalVars.appendDashboardPath(~url=path)->RescriptReactRouter.push}>
          {label->React.string}
        </button>
      )
      ->React.array}
    </div>
    <div className="overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-200 px-5 py-4">
        <h2 className="text-lg font-semibold text-slate-800"> {"商户管理"->React.string} </h2>
        <p className="mt-1 text-sm text-slate-500">
          {"仅显示当前管理员有权管理的商户。"->React.string}
        </p>
      </div>
      <div className="divide-y divide-slate-100">
        {merchants
        ->Array.map(merchant =>
          <div key={merchant.id} className="flex items-center justify-between p-4 gap-4">
            <div className="flex flex-col gap-1">
              <span className="font-semibold text-slate-800"> {merchant.name->React.string} </span>
              <span className="text-sm text-slate-500"> {merchant.id->React.string} </span>
            </div>
            <button
              disabled=switching
              className="rounded-md border border-blue-600 bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
              onClick={_ => manageMerchant(merchant)->ignore}>
              {(merchant.id == merchantId ? "管理当前商户" : "进入商户")->React.string}
            </button>
          </div>
        )
        ->React.array}
      </div>
    </div>
    <ChannelDailyLimits />
  </section>
}
