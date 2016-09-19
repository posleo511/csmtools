# execfile("/mapr/mapr03r/analytic_users/msmck/usr/local/lib/csmtools/python/oracle_service.py")

class iriOracleCon(object):
    """A class to streamline writing Oracle queries to delimited files.
    
    Typical use:
        con = oracleQuery(user='<user>', passwd='<passwd>', host='<host>', 
                          port ='<port>', service='<service-name>')
        con.get(outfile='<outfile>', query='<query>'[, dlm="<delimiter>", escape ="\\"])
    
    Defaults: 
        dlm="|"
        escape="\\"
    
    Imports:
        csv
        cx_Oracle
        logging
     
    """
    
    def __init__(self, user, passwd, host, port, service):
        import cx_Oracle
        import logging
        logging.basicConfig(level = logging.DEBUG)
        self.logger = logging.getLogger(__name__)
        login = '%s/%s@%s:%s/%s'%(user, passwd, host, port, service)
        show_login = '%s@%s:%s/%s'%(user, host, port, service)
        self.user = user
        try:
            self.logger.info("Connecting to %s"%(show_login))
            self.con = cx_Oracle.connect(login)
        except (SystemExit, KeyboardInterrupt):
            raise
        except Exception, e:
            self.logger.error('Failed to establish connection', exc_info = True)
    
    def __exit__(self):
        self.con.close()
    
    def get(self, outfile, query = "", dlm = "|", escape = "\\"):
        import csv
        
        cur = self.con.cursor()
        cur.execute("ALTER SESSION SET PARALLEL_DEGREE_LIMIT = 4")
        cur.execute("ALTER SESSION ENABLE PARALLEL QUERY")
        
        try:
            self.logger.info("Trying Query...")
            cur.execute(query)
            r = cur.fetchall()
        except (SystemExit, KeyboardInterrupt):
            raise
        except Exception, e:
            self.logger.error('Failed to successfully execute query', exc_info = True)
        
        self.logger.info("Query Successful, Extracting...")
        col_names = []
        for i in range(0, len(cur.description)):
            col_names.append(cur.description[i][0])
        
        f = open(outfile, "w")
        csv.register_dialect('user_delimited', escapechar = escape, delimiter = dlm, 
                     quoting = csv.QUOTE_NONE)
        writer = csv.writer(f, lineterminator = '\n', dialect = 'user_delimited')
        self.logger.info("Writing Header...")
        writer.writerow(col_names)
        self.logger.info("Writing Rows...")
        for row in r:
            writer.writerow(row)
        
        self.logger.info("Done! Cleaning Up...")
        f.close()
        cur.close()
