// Presentation policy only. The API remains the authority for every operation.
let isCollectionRole = roleId =>
  roleId == "collection_merchant_admin" || roleId == "collection_merchant_view_only"

let isPlatformRole = roleId => roleId == "tenant_admin" || roleId == "internal_admin"

let isCollectionPath = path =>
  switch path {
  | list{}
  | list{"v2", "home"}
  | list{"home", ..._}
  | list{"payments", ..._}
  | list{"refunds", ..._}
  | list{"disputes", ..._}
  | list{"customers", ..._}
  | list{"payment-links", ..._}
  | list{"developer-api-keys", ..._}
  | list{"webhooks", ..._}
  | list{"users", ..._}
  | list{"analytics-payments", ..._}
  | list{"analytics-refunds", ..._}
  | list{"analytics-disputes", ..._}
  | list{"account-settings", "profile", ..._}
  | list{"unauthorized"} => true
  | _ => false
  }

let canVisit = (roleId, path) => {
  switch path {
  | list{"platform", ..._} => isPlatformRole(roleId)
  | _ => !isCollectionRole(roleId) || isCollectionPath(path)
  }
}
