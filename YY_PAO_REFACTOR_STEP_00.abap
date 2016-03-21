*&---------------------------------------------------------------------*
*&  Improving the Design of Existing Code in ABAP
*&    based on Refactoring, A First Example
*&---------------------------------------------------------------------*
REPORT yy_pao_refactor_step_00.

*& Production Code
CLASS lcl_movie DEFINITION.
  PUBLIC SECTION.
    CONSTANTS:
      childrens   TYPE i VALUE 2,
      new_release TYPE i VALUE 1,
      regular     TYPE i VALUE 0.
    METHODS:
      constructor
        IMPORTING
          iv_title      TYPE string
          iv_price_code TYPE i,
      set_price_code
        IMPORTING iv_arg TYPE i,
      price_code
        RETURNING VALUE(rv_price_code) TYPE i,
      title
        RETURNING VALUE(rv_title) TYPE string.

   PRIVATE SECTION.
     DATA:
       mv_title      TYPE string,
       mv_price_code TYPE i.
ENDCLASS.

CLASS lcl_rental DEFINITION.
  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING
          io_movie       TYPE REF TO lcl_movie
          iv_days_rented TYPE i,
      days_rented
        RETURNING VALUE(rv_days_rented) TYPE i,
      movie
        RETURNING VALUE(ro_movie) TYPE REF TO lcl_movie.

  PRIVATE SECTION.
    DATA:
      mo_movie       TYPE REF TO lcl_movie,
      mv_days_rented TYPE i.
ENDCLASS.

CLASS lcl_customer DEFINITION.
  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING iv_name TYPE string,
      add_rental
        IMPORTING io_arg TYPE REF TO lcl_rental,
      name
        RETURNING VALUE(rv_name) TYPE string,
      statement
        RETURNING VALUE(rv_result) TYPE string.

  PRIVATE SECTION.
    TYPES:
      tt_rentals TYPE STANDARD TABLE OF REF TO lcl_rental WITH EMPTY KEY.
    DATA:
      mv_name    TYPE string,
      mt_rentals TYPE tt_rentals.
ENDCLASS.

CLASS lcl_movie IMPLEMENTATION.

  METHOD constructor.
    mv_title      = iv_title.
    mv_price_code = iv_price_code.
  ENDMETHOD.

  METHOD set_price_code.
    mv_price_code = iv_arg.
  ENDMETHOD.

  METHOD price_code.
    rv_price_code = mv_price_code.
  ENDMETHOD.

  METHOD title.
    rv_title = mv_title.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_rental IMPLEMENTATION.

  METHOD constructor.
    mo_movie       = io_movie.
    mv_days_rented = iv_days_rented.
  ENDMETHOD.

  METHOD days_rented.
    rv_days_rented = mv_days_rented.
  ENDMETHOD.

  METHOD movie.
    ro_movie = mo_movie.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_customer IMPLEMENTATION.

  METHOD constructor.
    mv_name = iv_name.
  ENDMETHOD.

  METHOD add_rental.
    APPEND io_arg TO mt_rentals.
  ENDMETHOD.

  METHOD name.
    rv_name = mv_name.
  ENDMETHOD.

  METHOD statement.
    DATA(lv_total_amount) = VALUE f( ).
    DATA(lv_frequent_renter_points) = VALUE i( ).
    rv_result = |Rental Record for { name( ) }\n|.

    LOOP AT mt_rentals INTO DATA(lo_each).
      DATA(lv_this_amount) = VALUE f( ).

      " determine amounts for each line
      CASE lo_each->movie( )->price_code( ).
        WHEN lcl_movie=>regular.
          lv_this_amount = lv_this_amount + 2.
          IF lo_each->days_rented( ) > 2.
            lv_this_amount = lv_this_amount + ( lo_each->days_rented( ) - 2 ) * '1.5'.
          ENDIF.
        WHEN lcl_movie=>new_release.
          lv_this_amount = lv_this_amount + lo_each->days_rented( ) * 3.
        WHEN lcl_movie=>childrens.
          lv_this_amount = lv_this_amount + '1.5'.
          IF lo_each->days_rented( ) > 3.
            lv_this_amount = lv_this_amount + ( lo_each->days_rented( ) - 3 ) * '1.5'.
          ENDIF.
      ENDCASE.

      " add frequent renter points
      lv_frequent_renter_points = lv_frequent_renter_points + 1.
      " add bouns for a two day new release rental
      IF lo_each->movie( )->price_code( ) = lcl_movie=>new_release AND
         lo_each->days_rented( ) > 1.
        lv_frequent_renter_points = lv_frequent_renter_points + 1.
      ENDIF.

      " show figures for this rental
      rv_result = rv_result && |\t{ lo_each->movie( )->title( ) }\t{ lv_this_amount DECIMALS = 2 }\n|.
      lv_total_amount = lv_total_amount + lv_this_amount.
    ENDLOOP.

    " add footer lines
    rv_result = rv_result && |Amount owed is { lv_total_amount }\n|.
    rv_result = rv_result && |You earned { lv_frequent_renter_points } frequent renter points|.
  ENDMETHOD.

ENDCLASS.
