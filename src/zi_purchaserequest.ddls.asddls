@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Purchase Request'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_PurchaseRequest
  as select from zpr_header
  composition [0..*] of ZI_PurchaseRequestItem as _Item
  association [0..1] to ZI_PRStatusVH          as _Status on $projection.Status = _Status.Status
{
  key pr_uuid                 as PrUuid,
      pr_id                   as PrId,
      description             as Description,
      requestor               as Requestor,
      company_code            as CompanyCode,
      purch_org               as PurchasingOrganization,
      purch_group             as PurchasingGroup,
      request_date            as RequestDate,
      needed_by               as NeededBy,
      status                  as Status,
      currency_code           as CurrencyCode,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_net_amount        as TotalNetAmount,
      notes                   as Notes,
      reject_reason           as RejectReason,
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
      _Item,
      _Status
}
