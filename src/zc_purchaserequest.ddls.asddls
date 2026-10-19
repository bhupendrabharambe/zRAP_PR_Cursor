@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Purchase Request'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: [ 'PrId' ]
define root view entity ZC_PurchaseRequest
  provider contract transactional_query
  as projection on ZI_PurchaseRequest
{
  key PrUuid,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      PrId,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      Description,
      Requestor,
      CompanyCode,
      PurchasingOrganization,
      PurchasingGroup,
      RequestDate,
      NeededBy,
      @ObjectModel.text.element: [ 'StatusText' ]
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_PRStatusVH', element: 'Status' } } ]
      Status,
      _Status.StatusText,
      _Status.Criticality as StatusCriticality,
      CurrencyCode,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalNetAmount,
      Notes,
      RejectReason,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      _Item : redirected to composition child ZC_PurchaseRequestItem,
      _Status
}
