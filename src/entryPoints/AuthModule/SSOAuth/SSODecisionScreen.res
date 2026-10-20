module SSOFromRedirect = {
  @react.component
  let make = (~localSSOState) => {
    open SSOTypes
    open APIUtils
    let includeCredentials = switch localSSOState {
    | SSO_FROM_REDIRECT(#Rauthy(_)) => true
    | _ => false
    }
    let updateDetails = useUpdateMethod(~includeCredentials)
    let getURL = useGetURL()

    let {setAuthStatus} = React.useContext(AuthInfoProvider.authStatusContext)

    let signInWithSSO = async () => {
      open AuthUtils
      try {
        let body = switch localSSOState {
        | SSO_FROM_REDIRECT(#Okta(data)) | SSO_FROM_REDIRECT(#Rauthy(data)) =>
          data->Identity.genericTypeToJson
        | _ => Dict.make()->JSON.Encode.object
        }
        let ssoUrl = getURL(~entityName=V1(USERS), ~userType=#SIGN_IN_WITH_SSO, ~methodType=Post)
        let response = await updateDetails(ssoUrl, body, Post)
        setAuthStatus(PreLogin(getPreLoginInfo(response)))
      } catch {
      | _ => setAuthStatus(LoggedOut)
      }
    }

    React.useEffect(() => {
      signInWithSSO()->ignore
      None
    }, [])

    <HSwitchUtils.BackgroundImageWrapper customPageCss="font-semibold md:text-3xl p-16">
      <div className="h-full w-full flex justify-center items-center text-white opacity-90">
        {"You will be redirected to the dashboard..."->React.string}
      </div>
    </HSwitchUtils.BackgroundImageWrapper>
  }
}

@react.component
let make = (~auth_id: option<string>) => {
  open SSOTypes
  let url = RescriptReactRouter.useUrl()
  let path = url.path->List.toArray->Array.joinWith("/")
  let (localSSOState, setLocalSSOState) = React.useState(_ => LOADING)

  let oidcMethod = provider => {
    open LogicUtils
    let dict = url.search->getDictFromUrlSearchParams
    let okta = {
      code: dict->Dict.get("code"),
      state: dict->Dict.get("state"),
    }
    setLocalSSOState(_ => SSO_FROM_REDIRECT(provider == "rauthy" ? #Rauthy(okta) : #Okta(okta)))
  }

  React.useEffect(() => {
    switch (url.path, auth_id) {
    | (list{"redirect", "oidc", "okta"}, _) => oidcMethod("okta")
    | (list{"redirect", "oidc", "rauthy"}, _) => oidcMethod("rauthy")
    | (_, Some(str)) => Window.Location.replace(`${Window.env.apiBaseUrl}/user/auth/url?id=${str}`)
    | _ => ()
    }
    None
  }, [path])

  switch localSSOState {
  | SSO_FROM_REDIRECT(_) => <SSOFromRedirect localSSOState />
  | LOADING => <PageLoaderWrapper.ScreenLoader sectionHeight="h-screen" />
  }
}
