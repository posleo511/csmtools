%MACRO DLM_DUMP(DSNAME, SASLB, OUTNAME, DEST, HOST);

  %IF %sysfunc(exist(&SASLB..&DSNAME)) %THEN %DO;

    PROC SQL;
    SELECT 
      CATS(LOWCASE(NAME)) length=1000,
      CATS(LOWCASE(TYPE)) length=1000 
    INTO
      :NAME SEPARATED BY ',',
      :TYPE SEPARATED BY ',' 
    FROM DICTIONARY.COLUMNS 
    WHERE UPCASE(LIBNAME)=UPCASE("&SASLB.") AND UPCASE(MEMNAME)=UPCASE("&DSNAME");
    
    
    DATA _NULL_;
      SET &SASLB..&DSNAME;
      FILE "&OUTNAME..csv" DSD DLM=",";
      IF _N_ = 1 THEN PUT "&NAME";  
      PUT (_all_) (&);
    RUN;
    
    DATA SETUP;
      MODIF = 'mo';
      DELIM = ',';
      ENDING=",";
      NCOLS = COUNTW("&NAME", DELIM, MODIF);
      DO I=1 TO NCOLS;
        nm = SCAN("&NAME", I, DELIM, MODIF);
        tp = SCAN("&TYPE", I, DELIM, MODIF);
        IF UPCASE(TP) = 'NUM' THEN TYP = "DECIMAL(38, 10)";
        ELSE IF UPCASE(TP) = 'CHAR' THEN TYP = 'STRING';
        ELSE TYP = 'UNKNOWN';
        IF I = NCOLS THEN ENDING = '';
        FMT = DEQUOTE(STRIP(NM) ||' '|| STRIP(TYP) || STRIP(ENDING));
        OUTPUT;
      END;
    RUN;
    
    PROC PRINT DATA = SETUP; RUN;

    DATA _NULL_;
      SET SETUP (KEEP = FMT);
      FILE "&OUTNAME..meta" DLM = ",";
      PUT (_ALL_) (&);
    RUN;
    
    /* IMPORTANT: PAWWSORDLESS SSH KEY BRIDGE MUST BE SET UP FOR YOUR USER! */  
    x "scp &OUTNAME..csv &HOST.:&DEST./";
    x "scp &OUTNAME..meta &HOST.:&DEST./";
  %END;

  %ELSE %DO;
    %PUT "USER_DERROR: The data set &SASLB..&DSNAME does not exist!";
  %END;

%MEND;