*&---------------------------------------------------------------------*
*&  Improving the Design of Existing Code in ABAP
*&    based on Refactoring, A First Example
*&---------------------------------------------------------------------*
REPORT yy_pao_refactor_step_04.

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
        RETURNING VALUE(ro_movie) TYPE REF TO lcl_movie,
      charge
        RETURNING VALUE(rv_result) TYPE f,
      frequent_renter_points
        RETURNING VALUE(rv_result) TYPE i.

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
    METHODS:
      total_charge
        RETURNING VALUE(rv_result) TYPE f,
      total_frequent_renter_points
        RETURNING VALUE(rv_result) type i.
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

  METHOD charge.
    rv_result = 0.
    CASE movie( )->price_code( ).
      WHEN lcl_movie=>regular.
        rv_result = rv_result + 2.
        IF days_rented( ) > 2.
          rv_result = rv_result + ( days_rented( ) - 2 ) * '1.5'.
        ENDIF.
      WHEN lcl_movie=>new_release.
        rv_result = rv_result + days_rented( ) * 3.
      WHEN lcl_movie=>childrens.
        rv_result = rv_result + '1.5'.
        IF days_rented( ) > 3.
          rv_result = rv_result + ( days_rented( ) - 3 ) * '1.5'.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD frequent_renter_points.
    IF movie( )->price_code( ) = lcl_movie=>new_release AND days_rented( ) > 1.
      rv_result = 2.
    ELSE.
      rv_result = 1.
    ENDIF.
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
    rv_result = |Rental Record for { name( ) }\n|.

    LOOP AT mt_rentals INTO DATA(lo_each).
      " show figures for this rental
      rv_result = rv_result && |\t{ lo_each->movie( )->title( ) }\t{ lo_each->charge( ) DECIMALS = 2 }\n|.
    ENDLOOP.

    " add footer lines
    rv_result = rv_result && |Amount owed is { total_charge( ) DECIMALS = 2 }\n|.
    rv_result = rv_result && |You earned { total_frequent_renter_points( ) } frequent renter points|.
  ENDMETHOD.

  METHOD total_charge.
    LOOP AT mt_rentals INTO DATA(lo_each).
      rv_result = rv_result + lo_each->charge( ).
    ENDLOOP.
  ENDMETHOD.

  METHOD total_frequent_renter_points.
    LOOP AT mt_rentals INTO DATA(lo_each).
      rv_result = rv_result + lo_each->frequent_renter_points( ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


*& Test Code
CLASS lth_customer_builder DEFINITION.
  PUBLIC SECTION.
    TYPES:
      tt_rentals TYPE STANDARD TABLE OF REF TO lcl_rental WITH EMPTY KEY.
    CONSTANTS:
      name TYPE string VALUE 'Gregory'.
    METHODS:
      build
        RETURNING VALUE(ro_result) TYPE REF TO lcl_customer,
      with_name
        IMPORTING iv_name      TYPE string
        RETURNING VALUE(ro_me) TYPE REF TO lth_customer_builder,
      with_rentals
        IMPORTING it_rentals   TYPE tt_rentals
        RETURNING VALUE(ro_me) TYPE REF TO lth_customer_builder.

  PRIVATE SECTION.
    DATA:
      mv_name    TYPE string VALUE name,
      mt_rentals TYPE tt_rentals.
ENDCLASS.

CLASS ltc_customer_test DEFINITION
  INHERITING FROM cl_aunit_assert
  FOR TESTING RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      test_customer FOR TESTING,
      test_add_rental FOR TESTING,
      test_get_name FOR TESTING,
      statement_for_regular_movie FOR TESTING,
      statement_for_new_release FOR TESTING,
      statement_for_childrens_movie FOR TESTING,
      statement_for_many_movies FOR TESTING.
ENDCLASS.

CLASS lth_customer_builder IMPLEMENTATION.

  METHOD build.
    ro_result = NEW #( mv_name ).
    LOOP AT mt_rentals INTO DATA(lo_rental).
      ro_result->add_rental( lo_rental ).
    ENDLOOP.
  ENDMETHOD.

  METHOD with_name.
    mv_name = iv_name.
    ro_me = me.
  ENDMETHOD.

  METHOD with_rentals.
    APPEND LINES OF it_rentals TO mt_rentals.
    ro_me = me.
  ENDMETHOD.

ENDCLASS.

CLASS ltc_customer_test IMPLEMENTATION.

  METHOD test_customer.
    DATA(lo_c) = NEW lth_customer_builder( )->build( ).
    assert_not_initial( lo_c ).
  ENDMETHOD.

  METHOD test_add_rental.
    DATA(lo_customer) = NEW lth_customer_builder( )->with_name( |Sallie| )->build( ).
    DATA(lo_movie) = NEW lcl_movie( iv_title      = |Gone with the Wind|
                                    iv_price_code = lcl_movie=>regular ).
    DATA(lo_rental) = NEW lcl_rental( io_movie       = lo_movie
                                      iv_days_rented = 3 ).
    lo_customer->add_rental( lo_rental ).
  ENDMETHOD.

  METHOD test_get_name.
    DATA(lo_customer) = NEW lth_customer_builder( )->with_name( |David| )->build( ).
    assert_equals( act = lo_customer->name( )
                   exp = |David| ).
  ENDMETHOD.

  METHOD statement_for_regular_movie.
    DATA(lo_rental) = NEW lcl_rental( io_movie = NEW #( iv_title = |Gone with the Wind|
                                                        iv_price_code = lcl_movie=>regular )
                                      iv_days_rented = 3 ).
    DATA(lo_customer) = NEW lth_customer_builder(
                          )->with_name( |Sallie|
                          )->with_rentals( VALUE #( ( lo_rental ) )
                          )->build( ).
    DATA(lv_expected) = |Rental Record for Sallie\n| &&
                        |\tGone with the Wind\t3.50\n| &&
                        |Amount owed is 3.50\n| &&
                        |You earned 1 frequent renter points|.
    assert_equals( exp = lv_expected
                   act = lo_customer->statement( ) ).
  ENDMETHOD.

  METHOD statement_for_new_release.
    DATA(lo_rental) = NEW lcl_rental( io_movie = NEW #( iv_title = |Star Wars|
                                                        iv_price_code = lcl_movie=>new_release )
                                      iv_days_rented = 3 ).
    DATA(lo_customer) = NEW lth_customer_builder(
                          )->with_name( |Sallie|
                          )->with_rentals( VALUE #( ( lo_rental ) )
                          )->build( ).
    DATA(lv_expected) = |Rental Record for Sallie\n| &&
                        |\tStar Wars\t9.00\n| &&
                        |Amount owed is 9.00\n| &&
                        |You earned 2 frequent renter points|.
    assert_equals( exp = lv_expected
                   act = lo_customer->statement( ) ).
  ENDMETHOD.

  METHOD statement_for_childrens_movie.
    DATA(lo_rental) = NEW lcl_rental( io_movie = NEW #( iv_title = |Madagascar|
                                                        iv_price_code = lcl_movie=>childrens )
                                      iv_days_rented = 3 ).
    DATA(lo_customer) = NEW lth_customer_builder(
                          )->with_name( |Sallie|
                          )->with_rentals( VALUE #( ( lo_rental ) )
                          )->build( ).
    DATA(lv_expected) = |Rental Record for Sallie\n| &&
                        |\tMadagascar\t1.50\n| &&
                        |Amount owed is 1.50\n| &&
                        |You earned 1 frequent renter points|.
    assert_equals( exp = lv_expected
                   act = lo_customer->statement( ) ).
  ENDMETHOD.

  METHOD statement_for_many_movies.
    DATA(lo_rental_1) = NEW lcl_rental( io_movie = NEW #( iv_title = |Madagascar|
                                                          iv_price_code = lcl_movie=>childrens )
                                        iv_days_rented = 6 ).
    DATA(lo_rental_2) = NEW lcl_rental( io_movie = NEW #( iv_title = |Star Wars|
                                                          iv_price_code = lcl_movie=>new_release )
                                        iv_days_rented = 2 ).
    DATA(lo_rental_3) = NEW lcl_rental( io_movie = NEW #( iv_title = |Gone with the Wind|
                                                          iv_price_code = lcl_movie=>regular )
                                        iv_days_rented = 8 ).
    DATA(lo_customer) = NEW lth_customer_builder(
                          )->with_name( |David|
                          )->with_rentals( VALUE #( ( lo_rental_1 ) ( lo_rental_2 ) ( lo_rental_3 ) )
                          )->build( ).
    DATA(lv_expected) = |Rental Record for David\n| &&
                        |\tMadagascar\t6.00\n| &&
                        |\tStar Wars\t6.00\n| &&
                        |\tGone with the Wind\t11.00\n| &&
                        |Amount owed is 23.00\n| &&
                        |You earned 4 frequent renter points|.
    assert_equals( exp = lv_expected
                   act = lo_customer->statement( ) ).
  ENDMETHOD.

  "TODO make test for price breaks in code
ENDCLASS.
