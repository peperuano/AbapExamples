report.
" table_data has to refer to a generic type "data" because it doesn't actually
" exist yet. 
data table_data type ref to data.
perform initialize_table using 5 5 changing table_data.
break-point.

" Init table creates a dynamic ABAP with a set height and width.
" data * ptrToData = initialize_table( int width, int height )
*&---------------------------------------------------------------------*
form initialize_table using width type i height type i changing board type ref to data.
  if ( width < 2 or height < 2 ). return. endif. " The table has to be at least so big

  data: dynamic_table type ref to data.
  data: dynamic_row   type ref to data.
  data: col_index type i value 1.
  data: columns type lvc_t_fcat.
  data: column  like line of columns.
  field-symbols <table> type any table.
  field-symbols <row> type any.

  do width times. " The columns which are going to represent our X axis positions
    column-fieldname = '_' && col_index.
    column-datatype  = cl_abap_structdescr=>typekind_char.
    column-inttype   = cl_abap_structdescr=>typekind_char.
    column-intlen    = 1.
    column-decimals  = 0.
    col_index = col_index + 1.
    append column to columns.
  enddo.

  " A table is nothing more really than a 2D array
  cl_alv_table_create=>create_dynamic_table(
    exporting it_fieldcatalog = columns
    importing ep_table = dynamic_table
  ).

  assign dynamic_table->* to <table>.
  create data dynamic_row like line of <table>.
  assign dynamic_row->* to <row>.

  do height times. " Each row is going to represent our Y axis positions
    insert <row> into table <table>.
  enddo.

  break-point.

endform.
