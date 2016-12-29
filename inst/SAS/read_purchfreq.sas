%MACRO READ_PURCHFREQ(DSNAME, LIB, DIR);

  /* NOTE: FOR THIS TO WORK OVER MOUNTED DRIVES YOU MUST SPECIFY:
      OPTIONS FILELOCKS=NONE */
  FILENAME DIRLIST PIPE "ls &DIR/purchfreq";

  DATA DIRLIST;
    LENGTH FNAME $256;
    INFILE DIRLIST LENGTH=RECLEN ;
    INPUT FNAME $VARYING256. RECLEN ;
    FILEPATH = "&DIR/purchfreq/"||FNAME;
  RUN;

  DATA &LIB..&DSNAME (DROP=FNAME DESCR UPC);
    SET DIRLIST;
    INFILE DUMMY FILEVAR = FILEPATH LENGTH=RECLEN END=DONE DSD DLM = "|" MISSOVER FIRSTOBS = 2;
    DO WHILE(NOT DONE);
      INPUT
        TRIPTYPE
        COUNT
        PERCENT
        ;
      OUTPUT;
    END;
  RUN;

%MEND READ_PURCHFREQ;

