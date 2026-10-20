@react.component
let make = (~onClick) => {
  let url = RescriptReactRouter.useUrl()
  let (errorMessage, setErrorMessage) = React.useState(_ => "")
  let (screenState, setScreenState) = React.useState(_ => PageLoaderWrapper.Loading)
  let {setAuthStatus, authStatus} = React.useContext(AuthInfoProvider.authStatusContext)
  let token = switch authStatus {
  | PreLogin(preLoginInfo) => preLoginInfo.token
  | _ => None
  }
  let userInfo = async () => {
    open HSLocalStorage
    try {
      let dict = [("token", token->Option.getOr("")->JSON.Encode.string)]->Dict.fromArray
      let info = AuthUtils.getAuthInfo(dict->JSON.Encode.object)

      setAuthStatus(LoggedIn(Auth(info)))
      // The callback is an authentication route, not a merchant dashboard page.
      switch (url.path, url.path->HSwitchUtils.urlPath) {
      | (list{"redirect", "oidc", _}, _)
      | (_, list{"redirect", "oidc", _}) =>
        RescriptReactRouter.replace(GlobalVars.appendDashboardPath(~url="/home"))
      | _ => ()
      }
      removeItemFromLocalStorage(~key="PRE_LOGIN_INFO")
      removeItemFromLocalStorage(~key="email_token")
      removeItemFromLocalStorage(~key="code")
      setScreenState(_ => PageLoaderWrapper.Success)
    } catch {
    | Exn.Error(e) => {
        let err = Exn.message(e)->Option.getOr("Verification Failed")
        setErrorMessage(_ => err)
        setAuthStatus(LoggedOut)
      }
    }
  }

  React.useEffect(() => {
    userInfo()->ignore
    None
  }, [])

  <PageLoaderWrapper screenState>
    <EmailVerifyScreen
      errorMessage onClick transitionMessage="You will be redirecting to the dashboard.."
    />
  </PageLoaderWrapper>
}
