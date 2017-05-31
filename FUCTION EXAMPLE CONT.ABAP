FUNCTION Z_HR_ABC.
*"----------------------------------------------------------------------
*"*"Interface locale :
*"  IMPORTING
*"     VALUE(MPERIO) TYPE  CHAR2
*"     VALUE(APERIO) TYPE  CHAR4
*"     VALUE(SOCIETE) TYPE  BUKRS
*"     VALUE(MATRICULE) TYPE  PERNR_D OPTIONAL
*"     VALUE(ETABLISSEMENT) TYPE  CHAR2 OPTIONAL
*"     VALUE(RUNID) TYPE  P_EVNUM OPTIONAL
*"     VALUE(STATUS) TYPE  P_EVSTATUS DEFAULT '50'
*"     VALUE(SIMU) TYPE  P_EVSIMU DEFAULT ' '
*"  TABLES
*"      ECRITURES STRUCTURE  ZHR_ITF_ABC
*"  EXCEPTIONS
*"      NO_ENTRY
*"----------------------------------------------------------------------

*&----------------------------------------------------------------------
*&  TABLE PERIODES
*&----------------------------------------------------------------------
  DATA : BEGIN OF periodes OCCURS 0.
          INCLUDE STRUCTURE pevat.
  DATA : abkrs  TYPE abkrs,
         begda  TYPE d,
         endda  TYPE d,
         pabrp  TYPE pabrp,
         pabrj  TYPE pabrj,
         mperio TYPE char2,
         aperio TYPE char4,
         docnum TYPE ppdhd-docnum,
         pernr  LIKE ppoix-pernr,
         END OF periodes.

*&----------------------------------------------------------------------
*&  TABLE TRANCHES
*&----------------------------------------------------------------------
  DATA : BEGIN OF tranches OCCURS 0,
           abkrs TYPE abkrs,
           pabrp TYPE pabrp,
           pabrj TYPE pabrj,
           begda TYPE d,
           endda TYPE d,
         END OF tranches.

*&----------------------------------------------------------------------
*&  PARAMETRES
*&----------------------------------------------------------------------
  DATA : permo TYPE t549a-permo.

*&----------------------------------------------------------------------
*&  TABLE DES DONNEES I_PPDIT
*&----------------------------------------------------------------------
  DATA: BEGIN OF i_ppdit OCCURS 0,
          docnum LIKE ppdhd-docnum ,
          runid  LIKE ppdhd-runid ,
          blart  LIKE ppdhd-blart,
          doclin LIKE ppdit-doclin,
          budat  LIKE ppdhd-budat,
          bldat  LIKE ppdhd-bldat,
          abper  LIKE ppdit-abper,
          bukrs  LIKE ppdhd-bukrs,
          sgtxt  LIKE ppdit-sgtxt,
          zuonr  LIKE ppdit-zuonr,
          gsber  LIKE ppdit-gsber,
          pernr  LIKE ppoix-pernr,
          kostl  LIKE ppdit-kostl,
          ktosl  LIKE ppdit-ktosl,
          hkont  LIKE ppdit-hkont,
          lifnr  LIKE ppdit-lifnr,
          wrbtr  LIKE ppdit-wrbtr,
          waers  LIKE ppdit-waers,
        END OF i_ppdit.

*&----------------------------------------------------------------------
*&  TABLES INTERNE
*&----------------------------------------------------------------------
  DATA : it_pevst TYPE TABLE OF pevst WITH HEADER LINE.
  DATA : it_pevat TYPE TABLE OF pevat WITH HEADER LINE.
  DATA : it_ppoix TYPE TABLE OF ppoix WITH HEADER LINE.

*&----------------------------------------------------------------------
*&  PARAMETRES
*&----------------------------------------------------------------------
  DATA : gsber TYPE gsber.

*&----------------------------------------------------------------------
*&  RANGES
*&----------------------------------------------------------------------
  RANGES : r_runid FOR pevst-runid.

*&----------------------------------------------------------------------
*&  TRAITEMENT RUNID
*&----------------------------------------------------------------------
  REFRESH r_runid.

  IF runid IS NOT INITIAL.
    CLEAR r_runid.
    r_runid-low = runid.
    r_runid-option = 'EQ'.
    r_runid-sign = 'I'.
    APPEND r_runid.
  ENDIF.

*&----------------------------------------------------------------------
*&  CONCATENATION
*&----------------------------------------------------------------------
  CONCATENATE '%' etablissement '%' INTO gsber.

*&----------------------------------------------------------------------
*&  Sélection des documents à transmettre
*&----------------------------------------------------------------------
  SELECT a~type a~runid a~attr a~id a~value d~docnum p~pernr
    FROM pevat AS a
  INNER JOIN pevsh AS h
     ON h~type  = a~type
    AND h~runid = a~runid
  INNER JOIN pevst AS t
     ON t~type  = a~type
    AND t~runid = a~runid
  INNER JOIN ppdhd AS d
     ON d~evtyp = a~type
    AND d~runid = a~runid
  INNER JOIN ppoix as p
   ON  p~runid = a~runid
   INTO CORRESPONDING FIELDS OF TABLE periodes
  WHERE a~type   = 'PP'
    AND t~runid  IN r_runid
    AND a~attr   = 'AKPER'
    AND h~actual = 'X'
    AND t~simu   = simu
    AND h~status = status
    AND d~bukrs  = societe
    AND p~pernr = matricule.

*&----------------------------------------------------------------------
*&  LOOP AT PERIODES
*&----------------------------------------------------------------------
  LOOP AT periodes.
    periodes-abkrs = periodes-value(2).
    periodes-pabrp = periodes-value+3(2).
    periodes-pabrj = periodes-value+6(4).

    READ TABLE tranches WITH KEY abkrs = periodes-abkrs
                                 pabrp = periodes-pabrp
                                 pabrj = periodes-pabrj.
    IF sy-subrc = 0.
      periodes-begda  = tranches-begda.
      periodes-endda  = tranches-endda.
      periodes-mperio = tranches-endda+4(2).
      periodes-aperio = tranches-endda(4).
    ELSE.
      CLEAR permo.
      SELECT SINGLE permo FROM t549a
        INTO permo
       WHERE abkrs = periodes-abkrs.

      SELECT SINGLE * FROM t549q
       INTO CORRESPONDING FIELDS OF tranches
       WHERE permo = permo
         AND pabrj = periodes-pabrj
         AND pabrp = periodes-pabrp.

      tranches-abkrs = periodes-abkrs.

      APPEND tranches.

      periodes-begda  = tranches-begda.
      periodes-endda  = tranches-endda.
      periodes-mperio = tranches-endda+4(2).
      periodes-aperio = tranches-endda(4).
    ENDIF.

    IF periodes-aperio NE aperio OR periodes-mperio NE mperio.
      DELETE periodes.
    ELSE.
      MODIFY periodes.
    ENDIF.

  ENDLOOP.

  SORT periodes BY docnum.
*&----------------------------------------------------------------------
*&  ENDLOOP PERIODES
*&----------------------------------------------------------------------

  IF periodes[] IS INITIAL.
    RAISE no_entry.
  ELSE.

*&----------------------------------------------------------------------
*&  Sélection des données à transférer
*&----------------------------------------------------------------------
    REFRESH: it_pevst, it_pevat, it_ppoix.

    SELECT mandt type runid name simu FROM pevst
      INTO TABLE it_pevst
       FOR ALL ENTRIES IN periodes
     WHERE type = 'PP'
       AND runid = periodes-runid.

    SORT it_pevst.

    SELECT mandt type runid attr id value FROM pevat
      INTO TABLE it_pevat
       FOR ALL ENTRIES IN periodes
     WHERE type = 'PP'
       AND runid = periodes-runid
       AND attr = 'AKPER'.

    SORT it_pevat.

    SELECT * FROM ppoix
      INTO TABLE it_ppoix
      FOR ALL ENTRIES IN periodes
      WHERE runid = periodes-runid
      AND pernr = matricule.

    SORT it_ppoix BY pernr runid.

    SELECT ppdhd~docnum ppdhd~runid blart ppdit~doclin budat bldat abper
           ppdhd~bukrs sgtxt zuonr gsber ppoix~pernr
           kostl ktosl hkont lifnr wrbtr ppdit~waers
   APPENDING CORRESPONDING FIELDS OF TABLE i_ppdit
    FROM ppdhd INNER JOIN ppdit
      ON ppdit~docnum = ppdhd~docnum
      INNER JOIN ppdix
      ON ppdix~docnum = ppdit~docnum
      AND ppdix~doclin = ppdit~doclin
      INNER JOIN ppoix
      ON ppoix~runid  = ppdix~runid
      AND ppoix~tslin  = ppdix~linum
     FOR ALL ENTRIES IN periodes
   WHERE ppdhd~docnum = periodes-docnum
     AND ppoix~pernr = periodes-pernr
     AND ppdit~gsber LIKE gsber.

*&----------------------------------------------------------------------
*&  Transfert dans la table ECRITURES
*&----------------------------------------------------------------------
    LOOP AT i_ppdit.
      CLEAR ecritures.
      ecritures-rtype  = 'C'.
      ecritures-rste   = i_ppdit-bukrs.
      ecritures-retab  = i_ppdit-gsber+2(2).
      READ TABLE periodes WITH KEY docnum = i_ppdit-docnum
      BINARY SEARCH.
      READ TABLE it_ppoix WITH KEY pernr = periodes-pernr
                                   runid = periodes-runid
           BINARY SEARCH.
      IF sy-subrc = 0.
        ecritures-pernr  = it_ppoix-pernr.
      ENDIF.
      ecritures-rgen   = i_ppdit-hkont.
      ecritures-ranp   = i_ppdit-budat(4).
      ecritures-rmoisp = i_ppdit-budat+4(2).
      ecritures-rjourp = i_ppdit-budat+6(2).
      ecritures-rce    = '6'.
      ecritures-ddatoa = i_ppdit-bldat(4).
      ecritures-ddatom = i_ppdit-bldat+4(2).
      ecritures-ddatoj = i_ppdit-bldat+6(2).
      ecritures-djal   = '640'.
      ecritures-dpiece = i_ppdit-docnum+2.
      READ TABLE it_pevst WITH KEY type  = 'PP'
                                   runid = i_ppdit-runid
           BINARY SEARCH.
      IF sy-subrc = 0.
        ecritures-dlib = it_pevst-name.
      ENDIF.
      IF i_ppdit-wrbtr LT 0.
        ecritures-dmdev = 0 - ( i_ppdit-wrbtr * 100 ) .
      ELSE.
        ecritures-dmdev = i_ppdit-wrbtr * 100.
      ENDIF.
      ecritures-dfolio = 'PAI'.
      ecritures-dws    = 'SAL'.
      ecritures-dnolig = i_ppdit-doclin.
      ecritures-dcdev  = i_ppdit-waers.
      ecritures-rsect  = i_ppdit-kostl.
      ecritures-rsect5 = i_ppdit-gsber.
      IF i_ppdit-wrbtr LT 0.
        ecritures-dsens = '-'.
      ELSE.
        ecritures-dsens = '+'.
      ENDIF.
      APPEND ecritures.
    ENDLOOP.
  ENDIF.
ENDFUNCTION.