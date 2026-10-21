open LogicUtils
@val @scope("Math") external roundAmount: float => float = "round"

module Field = {
  @react.component
  let make = (~label, ~value, ~onChange, ~placeholder="") => {
    <label className="flex flex-col gap-1">
      <span className="text-sm font-semibold"> {label->React.string} </span>
      <input
        ariaLabel=label
        className="border rounded p-2"
        value
        placeholder
        onChange={event => onChange(ReactEvent.Form.target(event)["value"])}
      />
    </label>
  }
}

@react.component
let make = () => {
  let {merchantId} = React.useContext(UserInfoProvider.defaultContext).getCommonSessionDetails()
  let get = APIUtils.useGetMethod(~showErrorToast=false)
  let update = APIUtils.useUpdateMethod(~showErrorToast=false)
  let endpoint = APIUtils.resolveEndpoint(APIUtilsTypes.Default("configs/channel-limits"))
  let (rows, setRows) = React.useState(_ => [])
  let (merchant, setMerchant) = React.useState(_ => merchantId)
  let (channel, setChannel) = React.useState(_ => "")
  let (pool, setPool) = React.useState(_ => "")
  let (currency, setCurrency) = React.useState(_ => "USD")
  let (timezone, setTimezone) = React.useState(_ => "UTC")
  let (amount, setAmount) = React.useState(_ => "3000.00")
  let (enabled, setEnabled) = React.useState(_ => true)
  let (busy, setBusy) = React.useState(_ => false)
  let (message, setMessage) = React.useState(_ => "")
  let load = async () => {
    try {
      let result = await get(endpoint)
      setRows(_ => result->getArrayFromJson([]))
    } catch {
    | _ => setMessage(_ => "无法加载渠道限额，请检查平台权限与服务状态。")
    }
  }
  React.useEffect0(() => {
    load()->ignore
    None
  })
  let save = async () => {
    let decimals = amount->String.split(".")->Array.get(1)->Option.mapOr(0, String.length)
    if (
      decimals > CurrencyUtils.getAmountPrecisionDigits(currency) ||
        !Js.Re.test_(%re("/^(0|[1-9][0-9]{0,9})(\.[0-9]{1,4})?$/"), amount)
    ) {
      setMessage(_ => "请输入金额，并符合该币种的小数位要求。")
    } else {
      setBusy(_ => true)
      try {
        let minor =
          CurrencyUtils.convertCurrencyToLowestDenomination(
            ~amount=amount->Float.fromString->Option.getOr(0.0),
            ~currency,
          )->roundAmount
        let body =
          [
            ("merchant_id", merchant->JSON.Encode.string),
            ("merchant_connector_id", channel->JSON.Encode.string),
            ("pool_id", pool->JSON.Encode.string),
            ("currency", currency->JSON.Encode.string),
            ("timezone", timezone->JSON.Encode.string),
            ("daily_limit", minor->JSON.Encode.float),
            ("enabled", enabled->JSON.Encode.bool),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object
        let _ = await update(endpoint, body, Fetch.Post)
        setMessage(_ => "每日限额已保存。")
        await load()
      } catch {
      | _ =>
        setMessage(_ =>
          "保存失败，请检查商户、渠道、币种、时区及共享额度池。"
        )
      }
      setBusy(_ => false)
    }
  }
  <section
    dataTestId="channel-daily-limits"
    className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm flex flex-col gap-4">
    <h2 className="text-xl font-semibold text-slate-800"> {"渠道每日限额"->React.string} </h2>
    <p className="text-sm text-slate-600">
      {"待处理交易也占用额度。同一额度池下的渠道共享每日限额；修改额度池会影响所有关联渠道。"->React.string}
    </p>
    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
      <Field label="商户 ID" value=merchant onChange={v => setMerchant(_ => v)} />
      <Field label="渠道账户 ID" value=channel onChange={v => setChannel(_ => v)} />
      <Field
        label="共享额度池 ID"
        value=pool
        onChange={v => setPool(_ => v)}
        placeholder="独立渠道请使用唯一名称"
      />
      <Field label="币种" value=currency onChange={v => setCurrency(_ => v)} />
      <Field
        label="统计时区"
        value=timezone
        onChange={v => setTimezone(_ => v)}
        placeholder="Asia/Shanghai"
      />
      <Field label="每日限额" value=amount onChange={v => setAmount(_ => v)} />
    </div>
    <label>
      <input type_="checkbox" checked=enabled onChange={_ => setEnabled(v => !v)} />
      {" 启用此渠道"->React.string}
    </label>
    <button
      disabled=busy
      className="self-start rounded-md bg-blue-600 px-4 py-2 font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
      onClick={_ => save()->ignore}>
      {"保存每日限额"->React.string}
    </button>
    <p role="status"> {message->React.string} </p>
    {rows
    ->Array.map(row => {
      let dict = row->getDictFromJsonObject
      let id = dict->getString("merchant_connector_id", "")
      let curr = dict->getString("currency", "")
      let limit =
        (dict->getFloat("daily_limit", 0.0) /. CurrencyUtils.getCurrencyConversionFactor(curr))
          ->Float.toString
      let used =
        (dict->getFloat("used", 0.0) /. CurrencyUtils.getCurrencyConversionFactor(curr))
          ->Float.toString
      <button
        key={id ++ curr}
        className="border rounded p-3 text-left"
        onClick={_ => {
          setMerchant(_ => dict->getString("merchant_id", ""))
          setChannel(_ => id)
          setPool(_ => dict->getString("pool_id", ""))
          setCurrency(_ => curr)
          setTimezone(_ => dict->getString("timezone", "UTC"))
          setAmount(_ => limit)
          setEnabled(_ => dict->getBool("enabled", true))
        }}>
        {`${id}: ${used} / ${limit} ${curr} — ${dict->getString(
            "timezone",
            "UTC",
          )}`->React.string}
      </button>
    })
    ->React.array}
  </section>
}
