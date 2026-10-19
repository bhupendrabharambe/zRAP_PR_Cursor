CLASS lhc_PurchaseRequest DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF status,
        open      TYPE c LENGTH 2 VALUE '01',
        submitted TYPE c LENGTH 2 VALUE '02',
        approved  TYPE c LENGTH 2 VALUE '03',
        rejected  TYPE c LENGTH 2 VALUE '04',
      END OF status.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR PurchaseRequest RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR PurchaseRequest RESULT result.

    METHODS SetDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR PurchaseRequest~SetDefaults.

    METHODS SetPrId FOR DETERMINE ON SAVE
      IMPORTING keys FOR PurchaseRequest~SetPrId.

    METHODS CalculateTotal FOR DETERMINE ON SAVE
      IMPORTING keys FOR PurchaseRequest~CalculateTotal.

    METHODS ValidateHeader FOR VALIDATE ON SAVE
      IMPORTING keys FOR PurchaseRequest~ValidateHeader.

    METHODS Submit FOR MODIFY
      IMPORTING keys FOR ACTION PurchaseRequest~Submit RESULT result.

    METHODS Approve FOR MODIFY
      IMPORTING keys FOR ACTION PurchaseRequest~Approve RESULT result.

    METHODS Reject FOR MODIFY
      IMPORTING keys FOR ACTION PurchaseRequest~Reject RESULT result.
ENDCLASS.

CLASS lhc_PurchaseRequest IMPLEMENTATION.

  METHOD get_instance_authorizations.
    result = VALUE #( FOR key IN keys
                      ( %tky                    = key-%tky
                        %update                 = if_abap_behv=>auth-allowed
                        %delete                 = if_abap_behv=>auth-allowed
                        %action-Submit          = if_abap_behv=>auth-allowed
                        %action-Approve         = if_abap_behv=>auth-allowed
                        %action-Reject          = if_abap_behv=>auth-allowed
                        %assoc-_Item            = if_abap_behv=>auth-allowed ) ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    result = VALUE #( FOR header IN headers
      LET is_open      = xsdbool( header-Status = status-open )
          is_submitted = xsdbool( header-Status = status-submitted )
      IN
      ( %tky            = header-%tky
        %update         = COND #( WHEN is_open = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %delete         = COND #( WHEN is_open = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %assoc-_Item    = COND #( WHEN is_open = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-Submit  = COND #( WHEN is_open = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-Approve = COND #( WHEN is_submitted = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-Reject  = COND #( WHEN is_submitted = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled ) ) ).
  ENDMETHOD.

  METHOD SetDefaults.
    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      FIELDS ( Status RequestDate Requestor CurrencyCode )
      WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    DATA(today) = cl_abap_context_info=>get_system_date( ).
    DATA(user)  = cl_abap_context_info=>get_user_technical_name( ).

    MODIFY ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      UPDATE FIELDS ( Status RequestDate Requestor CurrencyCode )
      WITH VALUE #( FOR header IN headers
                    ( %tky         = header-%tky
                      Status       = COND #( WHEN header-Status IS INITIAL THEN status-open ELSE header-Status )
                      RequestDate  = COND #( WHEN header-RequestDate IS INITIAL THEN today ELSE header-RequestDate )
                      Requestor    = COND #( WHEN header-Requestor IS INITIAL THEN CONV #( user ) ELSE header-Requestor )
                      CurrencyCode = COND #( WHEN header-CurrencyCode IS INITIAL THEN 'USD' ELSE header-CurrencyCode ) ) ).
  ENDMETHOD.

  METHOD SetPrId.
    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      FIELDS ( PrId )
      WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    DELETE headers WHERE PrId IS NOT INITIAL.
    CHECK headers IS NOT INITIAL.

    SELECT FROM zpr_header
      FIELDS MAX( pr_id )
      WHERE pr_id LIKE 'PR%'
      INTO @DATA(max_id).

    DATA(next_number) = COND i( WHEN max_id IS INITIAL THEN 0 ELSE CONV i( max_id+2 ) ).

    LOOP AT headers ASSIGNING FIELD-SYMBOL(<header>).
      next_number += 1.
      <header>-PrId = |PR{ next_number WIDTH = 8 ALIGN = RIGHT PAD = '0' }|.
    ENDLOOP.

    MODIFY ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      UPDATE FIELDS ( PrId )
      WITH VALUE #( FOR header IN headers ( %tky = header-%tky PrId = header-PrId ) ).
  ENDMETHOD.

  METHOD CalculateTotal.
    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest BY \_Item
      FIELDS ( NetAmount )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT keys INTO DATA(key).
      DATA(total) = REDUCE zpr_header-total_net_amount(
        INIT sum TYPE zpr_header-total_net_amount
        FOR item IN items WHERE ( PrUuid = key-PrUuid )
        NEXT sum = sum + item-NetAmount ).

      MODIFY ENTITIES OF zi_purchaserequest IN LOCAL MODE
        ENTITY PurchaseRequest
        UPDATE FIELDS ( TotalNetAmount )
        WITH VALUE #( ( %tky = key-%tky TotalNetAmount = total ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD ValidateHeader.
    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      FIELDS ( Description CompanyCode CurrencyCode RequestDate NeededBy )
      WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    LOOP AT headers INTO DATA(header).
      IF header-Description IS INITIAL.
        APPEND VALUE #( %tky = header-%tky ) TO failed-purchaserequest.
        APPEND VALUE #( %tky = header-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Description is required' )
                        %element-Description = if_abap_behv=>mk-on ) TO reported-purchaserequest.
      ENDIF.

      IF header-CompanyCode IS INITIAL.
        APPEND VALUE #( %tky = header-%tky ) TO failed-purchaserequest.
        APPEND VALUE #( %tky = header-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Company code is required' )
                        %element-CompanyCode = if_abap_behv=>mk-on ) TO reported-purchaserequest.
      ENDIF.

      IF header-CurrencyCode IS INITIAL.
        APPEND VALUE #( %tky = header-%tky ) TO failed-purchaserequest.
        APPEND VALUE #( %tky = header-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Currency is required' )
                        %element-CurrencyCode = if_abap_behv=>mk-on ) TO reported-purchaserequest.
      ENDIF.

      IF header-NeededBy IS NOT INITIAL
         AND header-RequestDate IS NOT INITIAL
         AND header-NeededBy < header-RequestDate.
        APPEND VALUE #( %tky = header-%tky ) TO failed-purchaserequest.
        APPEND VALUE #( %tky = header-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Needed-by date cannot be before the request date' )
                        %element-NeededBy = if_abap_behv=>mk-on ) TO reported-purchaserequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD Submit.
    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest BY \_Item
      FIELDS ( ItemNo Material Quantity )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT headers ASSIGNING FIELD-SYMBOL(<header>).
      IF <header>-Status <> status-open.
        APPEND VALUE #( %tky = <header>-%tky ) TO failed-purchaserequest.
        APPEND VALUE #( %tky = <header>-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Only open purchase requests can be submitted' )
                        %action-Submit = if_abap_behv=>mk-on ) TO reported-purchaserequest.
        CONTINUE.
      ENDIF.

      DATA(has_item) = xsdbool( line_exists( items[ PrUuid = <header>-PrUuid ] ) ).
      IF has_item = abap_false.
        APPEND VALUE #( %tky = <header>-%tky ) TO failed-purchaserequest.
        APPEND VALUE #( %tky = <header>-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Add at least one item before submitting' )
                        %action-Submit = if_abap_behv=>mk-on ) TO reported-purchaserequest.
      ENDIF.
    ENDLOOP.

    CHECK failed-purchaserequest IS INITIAL.

    MODIFY ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR header IN headers ( %tky = header-%tky Status = status-submitted ) ).

    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(updated).

    result = VALUE #( FOR header IN updated ( %tky = header-%tky %param = CORRESPONDING #( header ) ) ).
  ENDMETHOD.

  METHOD Approve.
    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    LOOP AT headers INTO DATA(header).
      IF header-Status <> status-submitted.
        APPEND VALUE #( %tky = header-%tky ) TO failed-purchaserequest.
        APPEND VALUE #( %tky = header-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Only submitted purchase requests can be approved' )
                        %action-Approve = if_abap_behv=>mk-on ) TO reported-purchaserequest.
      ENDIF.
    ENDLOOP.

    CHECK failed-purchaserequest IS INITIAL.

    MODIFY ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR h IN headers ( %tky = h-%tky Status = status-approved ) ).

    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(updated).

    result = VALUE #( FOR h IN updated ( %tky = h-%tky %param = CORRESPONDING #( h ) ) ).
  ENDMETHOD.

  METHOD Reject.
    LOOP AT keys INTO DATA(key).
      IF key-%param-RejectReason IS INITIAL.
        APPEND VALUE #( %tky = key-%tky ) TO failed-purchaserequest.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'A reject reason is required' )
                        %action-Reject = if_abap_behv=>mk-on ) TO reported-purchaserequest.
      ENDIF.
    ENDLOOP.

    CHECK failed-purchaserequest IS INITIAL.

    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    LOOP AT headers INTO DATA(header).
      IF header-Status <> status-submitted.
        APPEND VALUE #( %tky = header-%tky ) TO failed-purchaserequest.
        APPEND VALUE #( %tky = header-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Only submitted purchase requests can be rejected' )
                        %action-Reject = if_abap_behv=>mk-on ) TO reported-purchaserequest.
      ENDIF.
    ENDLOOP.

    CHECK failed-purchaserequest IS INITIAL.

    MODIFY ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      UPDATE FIELDS ( Status RejectReason )
      WITH VALUE #( FOR k IN keys
                    ( %tky          = k-%tky
                      Status        = status-rejected
                      RejectReason  = k-%param-RejectReason ) ).

    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(updated).

    result = VALUE #( FOR h IN updated ( %tky = h-%tky %param = CORRESPONDING #( h ) ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_Item DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF status,
        open TYPE c LENGTH 2 VALUE '01',
      END OF status.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Item RESULT result.

    METHODS SetItemDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Item~SetItemDefaults.

    METHODS SetItemNo FOR DETERMINE ON SAVE
      IMPORTING keys FOR Item~SetItemNo.

    METHODS CalculateAmounts FOR DETERMINE ON SAVE
      IMPORTING keys FOR Item~CalculateAmounts.

    METHODS ValidateItem FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~ValidateItem.
ENDCLASS.

CLASS lhc_Item IMPLEMENTATION.

  METHOD get_instance_features.
    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY Item
      FIELDS ( PrUuid )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY Item BY \_Header
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    result = VALUE #( FOR item IN items
      LET header_status = VALUE #( headers[ PrUuid = item-PrUuid ]-Status OPTIONAL )
          is_open       = xsdbool( header_status = status-open )
      IN
      ( %tky    = item-%tky
        %update = COND #( WHEN is_open = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %delete = COND #( WHEN is_open = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled ) ) ).
  ENDMETHOD.

  METHOD SetItemDefaults.
    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY Item
      FIELDS ( PrUuid CurrencyCode DeliveryDate UnitOfMeasure )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY Item BY \_Header
      FIELDS ( CurrencyCode NeededBy )
      WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    MODIFY ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY Item
      UPDATE FIELDS ( CurrencyCode DeliveryDate UnitOfMeasure )
      WITH VALUE #( FOR item IN items
                    LET header = VALUE #( headers[ PrUuid = item-PrUuid ] OPTIONAL )
                    IN
                    ( %tky          = item-%tky
                      CurrencyCode  = COND #( WHEN item-CurrencyCode IS INITIAL THEN header-CurrencyCode ELSE item-CurrencyCode )
                      DeliveryDate  = COND #( WHEN item-DeliveryDate IS INITIAL THEN header-NeededBy ELSE item-DeliveryDate )
                      UnitOfMeasure = COND #( WHEN item-UnitOfMeasure IS INITIAL THEN 'EA' ELSE item-UnitOfMeasure ) ) ).
  ENDMETHOD.

  METHOD SetItemNo.
    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY Item
      FIELDS ( PrUuid ItemNo )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    DELETE items WHERE ItemNo IS NOT INITIAL.
    CHECK items IS NOT INITIAL.

    TYPES:
      BEGIN OF ty_next_item,
        pr_uuid TYPE sysuuid_x16,
        next_no TYPE zpr_item-item_no,
      END OF ty_next_item.
    DATA next_items TYPE HASHED TABLE OF ty_next_item WITH UNIQUE KEY pr_uuid.

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      READ TABLE next_items WITH TABLE KEY pr_uuid = <item>-PrUuid ASSIGNING FIELD-SYMBOL(<next>).
      IF sy-subrc <> 0.
        SELECT FROM zpr_item
          FIELDS MAX( item_no )
          WHERE pr_uuid = @<item>-PrUuid
          INTO @DATA(max_item).

        READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
          ENTITY PurchaseRequest BY \_Item
          FIELDS ( ItemNo )
          WITH VALUE #( ( PrUuid = <item>-PrUuid ) )
          RESULT DATA(siblings).

        LOOP AT siblings INTO DATA(sibling).
          IF sibling-ItemNo > max_item.
            max_item = sibling-ItemNo.
          ENDIF.
        ENDLOOP.

        INSERT VALUE ty_next_item( pr_uuid = <item>-PrUuid next_no = max_item ) INTO TABLE next_items ASSIGNING <next>.
      ENDIF.

      <next>-next_no = <next>-next_no + 10.
      <item>-ItemNo = <next>-next_no.
    ENDLOOP.

    MODIFY ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY Item
      UPDATE FIELDS ( ItemNo )
      WITH VALUE #( FOR item IN items ( %tky = item-%tky ItemNo = item-ItemNo ) ).
  ENDMETHOD.

  METHOD CalculateAmounts.
    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY Item
      FIELDS ( PrUuid Quantity NetPrice )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    IF items IS NOT INITIAL.
      MODIFY ENTITIES OF zi_purchaserequest IN LOCAL MODE
        ENTITY Item
        UPDATE FIELDS ( NetAmount )
        WITH VALUE #( FOR item IN items
                      ( %tky      = item-%tky
                        NetAmount = CONV zpr_item-net_amount( item-Quantity * item-NetPrice ) ) ).
    ENDIF.

    DATA header_keys TYPE TABLE FOR READ IMPORT zi_purchaserequest\\PurchaseRequest.
    LOOP AT items INTO DATA(item).
      APPEND VALUE #( PrUuid = item-PrUuid ) TO header_keys.
    ENDLOOP.
    SORT header_keys BY PrUuid.
    DELETE ADJACENT DUPLICATES FROM header_keys COMPARING PrUuid.
    CHECK header_keys IS NOT INITIAL.

    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY PurchaseRequest BY \_Item
      FIELDS ( NetAmount )
      WITH header_keys
      RESULT DATA(all_items).

    LOOP AT header_keys INTO DATA(header_key).
      DATA(total) = REDUCE zpr_header-total_net_amount(
        INIT sum TYPE zpr_header-total_net_amount
        FOR current IN all_items WHERE ( PrUuid = header_key-PrUuid )
        NEXT sum = sum + current-NetAmount ).

      MODIFY ENTITIES OF zi_purchaserequest IN LOCAL MODE
        ENTITY PurchaseRequest
        UPDATE FIELDS ( TotalNetAmount )
        WITH VALUE #( ( %tky = header_key-%tky TotalNetAmount = total ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD ValidateItem.
    READ ENTITIES OF zi_purchaserequest IN LOCAL MODE
      ENTITY Item
      FIELDS ( Material Plant Quantity UnitOfMeasure NetPrice AccountAssignmentCategory CostCenter )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items INTO DATA(item).
      IF item-Material IS INITIAL.
        APPEND VALUE #( %tky = item-%tky ) TO failed-item.
        APPEND VALUE #( %tky = item-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Material is required' )
                        %element-Material = if_abap_behv=>mk-on ) TO reported-item.
      ENDIF.

      IF item-Plant IS INITIAL.
        APPEND VALUE #( %tky = item-%tky ) TO failed-item.
        APPEND VALUE #( %tky = item-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Plant is required' )
                        %element-Plant = if_abap_behv=>mk-on ) TO reported-item.
      ENDIF.

      IF item-Quantity <= 0.
        APPEND VALUE #( %tky = item-%tky ) TO failed-item.
        APPEND VALUE #( %tky = item-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Quantity must be greater than zero' )
                        %element-Quantity = if_abap_behv=>mk-on ) TO reported-item.
      ENDIF.

      IF item-UnitOfMeasure IS INITIAL.
        APPEND VALUE #( %tky = item-%tky ) TO failed-item.
        APPEND VALUE #( %tky = item-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Unit of measure is required' )
                        %element-UnitOfMeasure = if_abap_behv=>mk-on ) TO reported-item.
      ENDIF.

      IF item-NetPrice < 0.
        APPEND VALUE #( %tky = item-%tky ) TO failed-item.
        APPEND VALUE #( %tky = item-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Net price cannot be negative' )
                        %element-NetPrice = if_abap_behv=>mk-on ) TO reported-item.
      ENDIF.

      IF item-AccountAssignmentCategory = 'K' AND item-CostCenter IS INITIAL.
        APPEND VALUE #( %tky = item-%tky ) TO failed-item.
        APPEND VALUE #( %tky = item-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Cost center is required for account assignment K' )
                        %element-CostCenter = if_abap_behv=>mk-on ) TO reported-item.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
