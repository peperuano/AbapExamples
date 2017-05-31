REPORT zhr_scramble_md LINE-SIZE 255 .



TABLES:    pernr.
INFOTYPES: 0001,
           0002,
           0006,
           0008,
           0009,
           0021,
           0057,
           0061,
           0062.


DATA: g_gbdat_real TYPE d,
      g_gbdat_fake TYPE d,
      g_mode       TYPE pspar-actio,
      g_multiplier TYPE bseg-wrbtr,
      g_gbdat_adj  TYPE p,
      g_salpct_adj TYPE p.

DATA: wa_return     TYPE bapireturn1,
      wa_record_key TYPE bapipakey,
      wa_pskey      TYPE pskey.

START-OF-SELECTION.

* Prevent this program from accidentally being run in HRP.
  IF sy-sysid = 'HRP'.
    MESSAGE e001(z1) WITH 'Program cannot be run in ' sy-sysid.
  ENDIF.

  if PNPPERNR is initial.
    MESSAGE e001(z1) WITH 'Fill Personel number selection' sy-sysid.
  endif.

  GET pernr.

  WRITE: /10 pernr-pernr.

  CALL FUNCTION 'BAPI_EMPLOYEE_ENQUEUE'
    EXPORTING
      number = pernr-pernr
    IMPORTING
      return = wa_return.

  IF NOT wa_return IS INITIAL.
    WRITE:/ wa_return-message.
    EXIT.
  ENDIF.


* 0001
  MOVE 'MOD' TO g_mode.
  LOOP AT p0001.
    IF p0001-endda > '20160101'.
      p0001-kostl = ''.
      p0001-orgeh = ''.
      p0001-plans = '99999999'.
      p0001-stell = ''.
    ENDIF.
*    p0001-SACHZ = ''.
    p0001-sname = 'XXXXX XXXXX XXXXX'.
    p0001-ename = 'XXXXX XXXXX XXXXX'.
    MOVE-CORRESPONDING p0001 TO wa_pskey.
    PERFORM update_infotype USING p0001 g_mode wa_pskey.
  ENDLOOP.



* 0002
  MOVE 'MOD' TO g_mode.
  LOOP AT p0002.
    p0002-perid = 'T12345678'.
    p0002-nachn = 'Primer Cognom'.
    p0002-nach2 = p0002-vorna  ='Segon cognom'.
    p0002-cname = 'Nom complet'.
    p0002-anred = '2'.
    p0002-gbdat+4(4) = '0101'.
    MOVE-CORRESPONDING p0002 TO wa_pskey.
    PERFORM update_infotype USING p0002 g_mode wa_pskey.
  ENDLOOP.

* 0006

  LOOP AT p0006.
    p0006-stras = 'Carrer i número'.
    p0006-telnr = '931234567'.
    p0006-num01 = '654321987'.
    p0006-num02 = ''.
    p0006-num03 = ''.
    p0006-num04 = ''.
    p0006-num05 = ''.
    p0006-num06 = ''.
    p0006-hsnmr = '012'.
    p0006-posta = '456'.
    MOVE-CORRESPONDING p0006 TO wa_pskey.
    PERFORM update_infotype USING p0006 g_mode wa_pskey.
  ENDLOOP.

* 0009
  LOOP AT p0009.
    p0009-zlsch = 'U'.
    p0009-banks = 'ES'.
    p0009-bankl = '00210001'.
    p0009-bankn = '1234567891'.
    p0009-bankp = ''.
    p0009-bkont = '70'.
    p0009-iban  = 'ES9100210001701234567891'.
    MOVE-CORRESPONDING p0009 TO wa_pskey.
    PERFORM update_infotype USING p0009 g_mode wa_pskey.
  ENDLOOP.

* 0021
  LOOP AT p0021.
    p0021-fgbdt = '19970101'.
    p0021-favor = 'Nombre de pila'.
    p0021-fanam = 'Apellido'.
    p0021-fgbna = 'Apellido de soltera'.
    p0021-fnac2 = 'Segundo apellido'.
    p0021-fcnam = 'Nombre completo'.
    MOVE-CORRESPONDING p0021 TO wa_pskey.
    PERFORM update_infotype USING p0021 g_mode wa_pskey.
  ENDLOOP.

* 0061
  LOOP AT p0061.
    p0061-natss = '081234567869'.
    MOVE-CORRESPONDING p0061 TO wa_pskey.
    PERFORM update_infotype USING p0061 g_mode wa_pskey.
  ENDLOOP.

* 0062
  LOOP AT p0062.
    p0062-codim = 'T12345678'.
    p0062-famst = '1'.
    MOVE-CORRESPONDING p0062 TO wa_pskey.
    PERFORM update_infotype USING p0062 g_mode wa_pskey.
  ENDLOOP.

  CALL FUNCTION 'BAPI_EMPLOYEE_DEQUEUE'
    EXPORTING
      number = pernr-pernr
    IMPORTING
      return = wa_return.

END-OF-SELECTION.
  WRITE:/ 'Employee data has been scrambled'.

*&---------------------------------------------------------------------*
*&      Form  CHANGE_DOB
*&---------------------------------------------------------------------*
*       Scramble date of birth
*----------------------------------------------------------------------*
*      -->P_GBDAT_REAL  Real DOB
*      <--P_GBDAT_FAKE  Fake DOB
*----------------------------------------------------------------------*
FORM change_dob USING    p_gbdat_real
                CHANGING p_gbdat_fake.
  DATA: l_value     TYPE bseg-wrbtr,
        l_abs_value TYPE bseg-wrbtr.

  DO.
    CALL FUNCTION 'RANDOM_P'
      EXPORTING
        rnd_min   = -3650
        rnd_max   = 3650
      IMPORTING
        rnd_value = l_value.

* This will adjust the persons DOB by at least 90 days
    l_abs_value = abs( l_value ).
    IF l_abs_value > 90.
      EXIT.
    ENDIF.
  ENDDO.

* Adjust the employee's age by +/- 10 years
  p_gbdat_fake = p_gbdat_real + l_value.


ENDFORM.                    " CHANGE_DOB

*&---------------------------------------------------------------------*
*&      Form  UPDATE_INFOTYPE
*&---------------------------------------------------------------------*
*       Use the BAPI to update the infotypes
*----------------------------------------------------------------------*
*      -->P_nnnn  Infotype Data
*      -->P_MODE  Operation (INS, MOD, or DEL)
*      -->P_PSKEY Infotype keys
*----------------------------------------------------------------------*
FORM update_infotype USING    p_nnnn p_mode p_pskey STRUCTURE pskey.

  CALL FUNCTION 'HR_INFOTYPE_OPERATION'
    EXPORTING
      infty         = p_pskey-infty
      number        = p_pskey-pernr
      subtype       = p_pskey-subty
      objectid      = p_pskey-objps
      lockindicator = p_pskey-sprps
      validitybegin = p_pskey-begda
      validityend   = p_pskey-endda
      recordnumber  = p_pskey-seqnr
      record        = p_nnnn
      operation     = p_mode
*     TCLAS         = 'A'
*     DIALOG_MODE   = '0'
*     NOCOMMIT      =
*     VIEW_IDENTIFIER  =
*     SECONDARY_RECORD =
    IMPORTING
      return        = wa_return
      key           = wa_record_key.
  IF wa_return-type = 'E'.

      WRITE:/
      p_pskey-pernr,
      p_pskey-infty,
      p_pskey-subty,
      p_pskey-objps,
      p_pskey-sprps,
      p_pskey-endda,
      p_pskey-begda,
      p_pskey-seqnr, 60 wa_return-message.


  ENDIF.


ENDFORM.                    " UPDATE_INFOTYPE

*&---------------------------------------------------------------------*
*&      Form  GET_RANDOM_NUMBER
*&---------------------------------------------------------------------*
*       Get a random number to multiply by the person's
*       salary, bonus, etc...
*----------------------------------------------------------------------*
*      <--P_MULTIPLIER  Random number
*----------------------------------------------------------------------*
FORM get_random_number CHANGING p_multiplier.

  DO.
    CALL FUNCTION 'RANDOM_P'
      EXPORTING
        rnd_min   = '0.80'
        rnd_max   = '1.20'
      IMPORTING
        rnd_value = p_multiplier.

* Adjust the number by at least 3%
    IF p_multiplier < '0.97' OR
       p_multiplier > '1.03'.
      EXIT.
    ENDIF.
  ENDDO.
ENDFORM.                    " GET_RANDOM_NUMBER