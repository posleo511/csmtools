%MACRO DLM_DUMP(DSNAME, SASLB, OUTNAME, DEST, HOST, DELIM);

  %IF %SYSFUNC(EXIST(&SASLB..&DSNAME)) %THEN %DO;

    OPTIONS LRECL=MAX;

    PROC SQL;
    SELECT
      CATS(LOWCASE(NAME)) length=5000,
      CATS(LOWCASE(TYPE)) length=5000
    INTO
      :NAME SEPARATED BY "&DELIM.",
      :TYPE SEPARATED BY ","
    FROM DICTIONARY.COLUMNS
    WHERE UPCASE(LIBNAME)=UPCASE("&SASLB.") AND UPCASE(MEMNAME)=UPCASE("&DSNAME");


    DATA _NULL_;
      SET &SASLB..&DSNAME;
      FILE "&OUTNAME..dat" DSD DLM="&DELIM.";
      IF _N_ = 1 THEN PUT "&NAME";
      PUT (_all_) (&);
    RUN;

    DATA SETUP;
      LENGTH NM $5000 TP $5000 FMT $10000;
      MODIF = 'mo';
      DELIM = ',';
      ENDING=",";
      NCOLS = COUNTW("&NAME", "&DELIM.", MODIF);
      DO I=1 TO NCOLS;
        NM = SCAN("&NAME", I, "&DELIM.", MODIF);
        TP = SCAN("&TYPE", I, ",", MODIF);
        IF UPCASE(TP) = 'NUM' THEN TYP = "DECIMAL(38, 10)";
        ELSE IF UPCASE(TP) = 'CHAR' THEN TYP = 'STRING';
        ELSE TYP = 'UNKNOWN';
        IF I = NCOLS THEN ENDING = '';
        FMT = DEQUOTE(STRIP(NM) ||' '|| STRIP(TYP) || STRIP(ENDING));
        OUTPUT;
      END;
    RUN;

    DATA RSETUP;
      LENGTH NM $5000 TP $5000 FMT $10000 TYP $15;
      MODIF = 'mo';
      NCOLS = COUNTW("&NAME", "&DELIM.", MODIF);
      DO I=1 TO NCOLS;
        NM = SCAN("&NAME", I, "&DELIM.", MODIF);
        TP = SCAN("&TYPE", I, ",", MODIF);
        IF UPCASE(TP) = 'NUM' THEN TYP = "numeric";
        ELSE IF UPCASE(TP) = 'CHAR' THEN TYP = 'character';
        ELSE TYP = 'character';
        FMT = DEQUOTE(STRIP(NM) ||'|'|| STRIP(TYP));
        OUTPUT;
      END;
    RUN;


    DATA _NULL_;
      SET SETUP (KEEP = FMT);
      FILE "&OUTNAME..meta" DLM = ",";
      PUT (_ALL_) (&);
    RUN;

    DATA _NULL_;
      SET RSETUP (KEEP = FMT);
      FILE "&OUTNAME..Rmeta" DLM = "|";
      PUT (_ALL_) (&);
    RUN;

    /* IMPORTANT: PAWWSORDLESS SSH KEY BRIDGE MUST BE SET UP FOR YOUR USER! */
    x "scp &OUTNAME..dat &HOST.:&DEST./";
    x "scp &OUTNAME..meta &HOST.:&DEST./";
    x "scp &OUTNAME..Rmeta &HOST.:&DEST./";
    x "rm -f &OUTNAME..dat";
    x "rm -f &OUTNAME..meta";
    x "rm -f &OUTNAME..Rmeta";
  %END;

  %ELSE %DO;
    %PUT "USER_DERROR: The data set &SASLB..&DSNAME does not exist!";
  %END;

%MEND;
