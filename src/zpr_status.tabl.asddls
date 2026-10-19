@EndUserText.label : 'Purchase Request Status'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
define table zpr_status {
  key client      : abp_client not null;
  key status      : abap.char(2) not null;
  status_text     : abap.char(20);
  criticality     : abap.int1;
}
