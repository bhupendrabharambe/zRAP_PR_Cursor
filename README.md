# Purchase Request RAP Application (`ZPR_RAP`)

Managed RAP business object for purchase requests. Draft is **not** enabled: each save is a real database commit, and Submit / Approve / Reject are instance actions with feature control.

## What you get

| Layer | Objects |
| --- | --- |
| Persistence | `ZPR_HEADER`, `ZPR_ITEM`, `ZPR_STATUS` |
| Interface BO | `ZI_PurchaseRequest` (root) + `ZI_PurchaseRequestItem` |
| Projection / UI | `ZC_PurchaseRequest`, `ZC_PurchaseRequestItem`, metadata extensions |
| Behavior | Managed, UUID early numbering, validations, determinations, actions |
| Service | `ZUI_PURCHASE_REQUEST` (expose in an OData V4 UI binding in ADT) |
| Setup | `ZCL_PR_DATA_SETUP` (class run to seed statuses) |

### Document flow

```
Open (01)  --Submit-->  Submitted (02)  --Approve-->  Approved (03)
                                  \
                                   --Reject-->  Rejected (04)
```

- Create / update / delete header and items only while **Open**
- Submit requires at least one item
- Reject requires a reason (popup parameter)
- Header total is the sum of item net amounts (`quantity * net price`)
- PR number is assigned on first save (`PR00000001`, …)

## Activate on an ABAP system

This repo is source for **ABAP Development Tools** (Eclipse) or **abapGit**. It cannot run inside this folder by itself.

1. Create package `ZPR_RAP` (or pull with abapGit into that package).
2. Import / activate in this order:
   - tables `ZPR_HEADER`, `ZPR_ITEM`, `ZPR_STATUS`
   - `ZI_PRStatusVH`, `ZI_PRRejectReason`
   - `ZI_PurchaseRequestItem`, `ZI_PurchaseRequest`
   - access controls
   - behavior definition `ZI_PurchaseRequest` and class `ZBP_I_PURCHASEREQUEST`
   - projections, metadata extensions, projection behavior
   - service definition `ZUI_PURCHASE_REQUEST`
3. Run `ZCL_PR_DATA_SETUP` (F9 in ADT) to load status value help.
4. Create service binding **`ZUI_PURCHASE_REQUEST_O4`**:
   - type **OData V4 - UI**
   - service `ZUI_PURCHASE_REQUEST`
   - publish
5. Preview the Fiori Elements List Report, or generate a Fiori app from the binding.

### Suggested Fiori UI

- List Report: `PurchaseRequest`
- Object Page: header facets + items composition table
- Actions on the list and object page: Submit, Approve, Reject

## Business rules (implemented)

Header: description, company code, and currency are mandatory; needed-by cannot be before request date.

Item: material, plant, quantity &gt; 0, UoM, and non-negative price; account assignment `K` requires a cost center.

Defaults on create: status Open, request date today, requestor = current user, currency `USD`, item UoM `EA`, item delivery date = header needed-by.

## Local development notes

- Customer namespace `Z`, managed RAP, **no draft** (as requested).
- DCL currently allows all users (`true = true`) so the demo activates without a PFCG role. Tighten this before any productive use.
- Status value help reads `ZPR_STATUS`; run the setup class after transport to a new client.
- Optional next steps: SNRO number range instead of `MAX(pr_id)`, released value helps (`I_CompanyCodeStdVH`, `I_ProductStdVH`, `I_PlantStdVH`), and an approval workflow.
