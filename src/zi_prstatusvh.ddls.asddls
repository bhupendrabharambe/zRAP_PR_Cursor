@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Request Status Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_PRStatusVH
  as select from zpr_status
{
      @ObjectModel.text.element: ['StatusText']
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
  key status      as Status,
      @Search.defaultSearchElement: true
      status_text as StatusText,
      criticality as Criticality
}
