%MACRO PRINT_COLNAMES(DSNAME, SASLB);
  
    OPTIONS NOCENTER;
    
    PROC SQL NOPRINT;
    SELECT 
      CATS(LOWCASE(NAME)) length=1000,
      CATS(LOWCASE(TYPE)) length=1000 
    INTO
      :NAME SEPARATED BY ',',
      :TYPE SEPARATED BY ',' 
    FROM DICTIONARY.COLUMNS 
    WHERE UPCASE(LIBNAME)=UPCASE("&SASLB.") AND UPCASE(MEMNAME)=UPCASE("&DSNAME");
    
    %IF &SQLOBS = 0 %THEN %DO;
      PROC CONTENTS DATA = &SASLB..&DSNAME. SHORT VARNUM;
      TITLE "++++ &SASLB..&DSNAME. HAD NO OBS ++++++++";
      RUN;
      %RETURN;
    %END;
    
    DATA SAS_SELECT_FMT;
      MODIF = 'mo';
      DELIM = ',';
      NCOLS = COUNTW("&NAME", DELIM, MODIF);
      DO I=1 TO NCOLS;
        nm = SCAN("&NAME", I, DELIM, MODIF);
        tp = SCAN("&TYPE", I, DELIM, MODIF);
        FMT = DEQUOTE(STRIP(NM));
        OUTPUT;
      END;
    RUN;
    
    DATA HIVE_SELECT_FMT;
      MODIF = 'mo';
      DELIM = ',';
      NCOLS = COUNTW("&NAME", DELIM, MODIF);
      DO I=1 TO NCOLS;
        nm = SCAN("&NAME", I, DELIM, MODIF);
        tp = SCAN("&TYPE", I, DELIM, MODIF);
        IF I = 1 THEN BEGS = ''; ELSE BEGS = ",";
        FMT = DEQUOTE(STRIP(BEGS) || ' ' || STRIP(NM));
        OUTPUT;
      END;
    RUN;
    
    DATA HIVE_FMT;
      MODIF = 'mo';
      DELIM = ',';
      BEGS=",";
      NCOLS = COUNTW("&NAME", DELIM, MODIF);
      DO I=1 TO NCOLS;
        nm = SCAN("&NAME", I, DELIM, MODIF);
        tp = SCAN("&TYPE", I, DELIM, MODIF);
        IF UPCASE(TP) = 'NUM' THEN TYP = "DECIMAL(38, 10)";
        ELSE IF UPCASE(TP) = 'CHAR' THEN TYP = 'STRING';
        ELSE TYP = 'UNKNOWN';
        IF I = 1 THEN BEGS = ''; ELSE BEGS = ",";
        FMT = DEQUOTE(STRIP(BEGS) || ' ' || STRIP(NM) ||' '|| STRIP(TYP));
        OUTPUT;
      END;
    RUN;
    
    PROC PRINT DATA = HIVE_FMT (KEEP = FMT) NOOBS split='*'; 
    TITLE "+++++++++++ HIVE FORMATS FOR &SASLB..&DSNAME. +++++++++++";
    VAR FMT;
    LABEL FMT = "*";
    RUN;
    
    PROC PRINT DATA = SAS_SELECT_FMT (KEEP = FMT) NOOBS split='*'; 
    TITLE "+++++++++++SAS SELECT FORMATS FOR &SASLB..&DSNAME.+++++++++++";
    VAR FMT;
    LABEL FMT = "*";
    RUN;
    
    PROC PRINT DATA = HIVE_SELECT_FMT (KEEP = FMT) NOOBS split='*'; 
    TITLE "+++++++++++HIVE SELECT FORMATS FOR &SASLB..&DSNAME.+++++++++++";
    VAR FMT;
    LABEL FMT = "*";
    RUN;
    
%MEND;