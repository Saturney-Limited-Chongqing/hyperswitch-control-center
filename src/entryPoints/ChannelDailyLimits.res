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
    | _ =>
      setMessage(_ =>
        "Unable to load channel limits. Check platform access and whether the service is enabled."
      )
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
      setMessage(_ =>
        "Enter an amount with the correct number of decimal places for this currency."
      )
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
        setMessage(_ => "Channel limit saved.")
        await load()
      } catch {
      | _ =>
        setMessage(_ =>
          "Unable to save. Verify the merchant, channel, currency, timezone and shared pool."
        )
      }
      setBusy(_ => false)
    }
  }
  <section dataTestId="channel-daily-limits" className="border rounded-lg p-5 flex flex-col gap-4">
    <h2 className="text-xl font-semibold"> {"Channel daily limits"->React.string} </h2>
    <p>
      {"Limits include pending payments. Channels sharing a pool share its daily allowance. Changing a shared pool affects every linked channel."->React.string}
    </p>
    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
      <Field label="Merchant ID" value=merchant onChange={v => setMerchant(_ => v)} />
      <Field label="Channel account ID" value=channel onChange={v => setChannel(_ => v)} />
      <Field
        label="Shared pool ID"
        value=pool
        onChange={v => setPool(_ => v)}
        placeholder="Use a unique name for an independent channel"
      />
      <Field label="Currency" value=currency onChange={v => setCurrency(_ => v)} />
      <Field
        label="Timezone"
        value=timezone
        onChange={v => setTimezone(_ => v)}
        placeholder="Asia/Shanghai"
      />
      <Field label="Daily amount" value=amount onChange={v => setAmount(_ => v)} />
    </div>
    <label>
      <input type_="checkbox" checked=enabled onChange={_ => setEnabled(v => !v)} />
      {" Channel enabled"->React.string}
    </label>
    <button disabled=busy className="border rounded px-4 py-2" onClick={_ => save()->ignore}>
      {"Save daily limit"->React.string}
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
