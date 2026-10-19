@EndUserText.label : 'Purchase Request Header'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zpr_header {
  key client            : abp_client not null;
  key pr_uuid           : sysuuid_x16 not null;
  pr_id                 : abap.char(10);
  description           : abap.char(60);
  requestor             : abp_creation_user;
  company_code          : abap.char(4);
  purch_org             : abap.char(4);
  purch_group           : abap.char(3);
  request_date          : abap.dats;
  needed_by             : abap.dats;
  status                : abap.char(2);
  currency_code         : abap.cuky;
  @Semantics.amount.currencyCode : 'zpr_header.currency_code'
  total_net_amount      : abap.curr(23,2);
  notes                 : abap.char(255);
  reject_reason         : abap.char(255);
  created_by            : abp_creation_user;
  created_at            : abp_creation_tstmpl;
  last_changed_by       : abp_lastchange_user;
  last_changed_at       : abp_lastchange_tstmpl;
  local_last_changed_at : abp_locinst_lastchange_tstmpl;
}
