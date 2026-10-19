@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Purchase Request Item'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: [ 'ItemNo' ]
define view entity ZC_PurchaseRequestItem
  provider contract transactional_query
  as projection on ZI_PurchaseRequestItem
{
  key ItemUuid,
      PrUuid,
      ItemNo,
      @Search.defaultSearchElement: true
      Material,
      MaterialGroup,
      Plant,
      StorageLocation,
      @Semantics.quantity.unitOfMeasure: 'UnitOfMeasure'
      Quantity,
      UnitOfMeasure,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      NetPrice,
      CurrencyCode,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      NetAmount,
      AccountAssignmentCategory,
      CostCenter,
      GLAccount,
      DeliveryDate,
      @Search.defaultSearchElement: true
      ItemText,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      _Header : redirected to parent ZC_PurchaseRequest
}
