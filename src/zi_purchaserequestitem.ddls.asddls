@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Purchase Request Item'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PurchaseRequestItem
  as select from zpr_item
  association to parent ZI_PurchaseRequest as _Header on $projection.PrUuid = _Header.PrUuid
{
  key item_uuid               as ItemUuid,
      pr_uuid                 as PrUuid,
      item_no                 as ItemNo,
      material                as Material,
      material_group          as MaterialGroup,
      plant                   as Plant,
      storage_location        as StorageLocation,
      @Semantics.quantity.unitOfMeasure: 'UnitOfMeasure'
      quantity                as Quantity,
      uom                     as UnitOfMeasure,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      net_price               as NetPrice,
      currency_code           as CurrencyCode,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      net_amount              as NetAmount,
      acct_assgmt_cat         as AccountAssignmentCategory,
      cost_center             as CostCenter,
      gl_account              as GLAccount,
      delivery_date           as DeliveryDate,
      item_text               as ItemText,
      @Semantics.user.createdBy: true
      created_by              as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at              as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by         as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at         as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at   as LocalLastChangedAt,
      _Header
}
