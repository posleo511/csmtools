%MACRO READ_THE_UPCS2(DSNAME, LIB, DIR);

  /* NOTE: FOR THIS TO WORK OVER MOUNTED DRIVES YOU MUST SPECIFY:
      OPTIONS FILELOCKS=NONE */
  FILENAME DIRLIST PIPE "ls &DIR/dictionary";

  DATA DIRLIST;
    LENGTH FNAME $256;
    INFILE DIRLIST LENGTH=RECLEN ;
    INPUT FNAME $VARYING256. RECLEN ;
    FILEPATH = "&DIR/dictionary/"||FNAME;
  RUN;

  DATA &LIB..&DSNAME (DROP=FNAME DESCR UPC);
    SET DIRLIST;
    LENGTH DESCR $100 UPC $15;
    INFILE DUMMY FILEVAR = FILEPATH LENGTH=RECLEN END=DONE DSD DLM = "|" MISSOVER FIRSTOBS = 2;
    DO WHILE(NOT DONE);
      INPUT
        SYS
        GEN
        VEN
        ITE
        KEYCAT
        DESCR $
        UPC $
        ;
      OUTPUT;
    END;
  RUN;

  DATA &LIB..&DSNAME;
    SET &LIB..&DSNAME;
    UPC = CATS(put(SYS,z2.), put(GEN,z2.), put(VEN,z5.), put(ITE,z5.)); /* ADDED BY MSMCK, BECAUSE THAT OTHER WAY IS JUST... THE WORST. */
  RUN;
%MEND READ_THE_UPCS2;
