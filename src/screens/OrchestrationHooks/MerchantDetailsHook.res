open APIUtils
open HyperswitchAtom
let useFetchUserMerchantDetails = () => {
  let getURL = useGetURL()
  let setMerchantDetailsValue = merchantDetailsValueAtom->Recoil.useSetRecoilState

  let fetchDetails = useGetMethod()

  let captureSession = DashboardSessionGuard.useGuard()
  async (~version: UserInfoTypes.version=V1) => {
    let isCurrentSession = captureSession()
    try {
      let merchantDetailsJSON = switch version {
      | V1 => {
          let detailsUrl = getURL(
            ~entityName=V1(USERS),
            ~userType=#MERCHANT_DETAILS,
            ~methodType=Get,
          )
          await fetchDetails(detailsUrl)
        }
      | V2 => {
          let detailsUrl = getURL(~entityName=V2(USER_MERCHANT_DETAILS), ~methodType=Get)
          await fetchDetails(detailsUrl, ~version=V2)
        }
      }
      let (product_type, merchant_account_type) =
        merchantDetailsJSON->MerchantAccountDetailsMapper.getUserMerchantDetails(~version)
      if !isCurrentSession() {
        Exn.raiseError("Dashboard session changed")
      }
      setMerchantDetailsValue(prev => {...prev, product_type, merchant_account_type})
      product_type
    } catch {
    | Exn.Error(e) => {
        let err = Exn.message(e)->Option.getOr("Failed to fetch merchant details!")
        Exn.raiseError(err)
      }
    }
  }
}

let useFetchMerchantDetails = () => {
  let getURL = useGetURL()
  let setMerchantDetailsValue = merchantDetailsValueAtom->Recoil.useSetRecoilState

  let fetchDetails = useGetMethod()

  let captureSession = DashboardSessionGuard.useGuard()
  async (~version: UserInfoTypes.version=V1) => {
    let isCurrentSession = captureSession()
    try {
      let merchantDetailsJSON = switch version {
      | V1 => {
          let accountUrl = getURL(~entityName=V1(MERCHANT_ACCOUNT), ~methodType=Get)
          await fetchDetails(accountUrl)
        }
      | V2 => {
          let accountUrl = getURL(~entityName=V2(MERCHANT_ACCOUNT), ~methodType=Get)
          await fetchDetails(accountUrl, ~version=V2)
        }
      }
      let jsonToTypedValue =
        merchantDetailsJSON->MerchantAccountDetailsMapper.getMerchantDetails(~version)
      if !isCurrentSession() {
        Exn.raiseError("Dashboard session changed")
      }
      setMerchantDetailsValue(_ => jsonToTypedValue)
      jsonToTypedValue
    } catch {
    | Exn.Error(e) => {
        let err = Exn.message(e)->Option.getOr("Failed to fetch merchant details!")
        Exn.raiseError(err)
      }
    }
  }
}

let useMerchantDetailsValue = () => Recoil.useRecoilValueFromAtom(merchantDetailsValueAtom)
