// Ignore responses issued under a previous merchant/profile or an unmounted page.
let useGuard = () => {
  let {orgId, merchantId, profileId, version} = React.useContext(
    UserInfoProvider.defaultContext,
  ).getCommonSessionDetails()
  let versionName = version == UserInfoTypes.V1 ? "v1" : "v2"
  let sessionKey = `${orgId}:${merchantId}:${profileId}:${versionName}`
  let current = React.useRef(sessionKey)
  let mounted = React.useRef(true)
  current.current = sessionKey
  React.useEffect(() => {
    mounted.current = true
    Some(() => mounted.current = false)
  }, [])
  () => {
    let requestedSession = sessionKey
    () => mounted.current && current.current == requestedSession
  }
}
