CLASS zcl_pr_data_setup DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_pr_data_setup IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA statuses TYPE STANDARD TABLE OF zpr_status WITH EMPTY KEY.

    statuses = VALUE #(
      ( status = '01' status_text = 'Open'      criticality = 2 )
      ( status = '02' status_text = 'Submitted' criticality = 0 )
      ( status = '03' status_text = 'Approved'  criticality = 3 )
      ( status = '04' status_text = 'Rejected'  criticality = 1 ) ).

    DELETE FROM zpr_status.
    INSERT zpr_status FROM TABLE @statuses.

    out->write( |Purchase request statuses loaded: { lines( statuses ) }| ).
    out->write( |01 Open / 02 Submitted / 03 Approved / 04 Rejected| ).
  ENDMETHOD.
ENDCLASS.
