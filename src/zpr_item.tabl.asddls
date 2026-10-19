@EndUserText.label : 'Purchase Request Item'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zpr_item {
  key client            : abp_client not null;
  key item_uuid         : sysuuid_x16 not null;
  pr_uuid               : sysuuid_x16 not null;
  item_no               : abap.numc(5);
  material              : abap.char(40);
  material_group        : abap.char(9);
  plant                 : abap.char(4);
  storage_location      : abap.char(4);
  @Semantics.quantity.unitOfMeasure : 'zpr_item.uom'
  quantity              : abap.quan(13,3);
  uom                   : abap.unit(3);
  @Semantics.amount.currencyCode : 'zpr_item.currency_code'
  net_price             : abap.curr(23,2);
  currency_code         : abap.cuky;
  @Semantics.amount.currencyCode : 'zpr_item.currency_code'
  net_amount            : abap.curr(23,2);
  acct_assgmt_cat       : abap.char(1);
  cost_center           : abap.char(10);
  gl_account            : abap.char(10);
  delivery_date         : abap.dats;
  item_text             : abap.char(40);
  created_by            : abp_creation_user;
  created_at            : abp_creation_tstmpl;
  last_changed_by       : abp_lastchange_user;
  last_changed_at       : abp_lastchange_tstmpl;
  local_last_changed_at : abp_locinst_lastchange_tstmpl;
}
