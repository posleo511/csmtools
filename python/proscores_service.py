import sys
sys.path.append('/home/mspra/anaconda2/lib/python2.7/site-packages/')
import os, socket
import cx_Oracle
import pandas as pd
import numpy as np
import hashlib
import glob
import base64
import pyper as pr
import cPickle as pickle
import time
import datetime as dt
from subprocess import *
import gc
gc.collect()

def log_message(message_text,verbose=True,return_iri_week=False):
    ts=time.localtime()
    timestamp="%s-%s-%s_%s:%s:%s" %(ts.tm_year,
                                    ts.tm_mon,
                                    ts.tm_mday,
                                    ts.tm_hour,
                                    ts.tm_min,
                                    ts.tm_sec)
    line= "%s\t%s\n"%(timestamp,message_text)
    if(verbose):
        print line
    logfile = open("%s/logfiles/log_%s-%s-%s-%s.txt"%(folder,ts.tm_year,ts.tm_mon,ts.tm_mday,socket.gethostname().split('.')[0]),'a')
    logfile.writelines(line)
    logfile.close()
    if(return_iri_week):
        d=dt.datetime(ts.tm_year,ts.tm_mon,ts.tm_mday)
        d=pd.to_datetime(d)
        d=pd.Timestamp(d)
        iri_week_2016=1892
        year_multiplier=(ts.tm_year-2016)*52
        return (iri_week_2016+d.weekofyear+year_multiplier)


class SQLDevel(object):
    def __init__(self, user, password, host, service, folder, clear_results=True):
        self.user = user
        self.password = password
        self.con = cx_Oracle.connect('%s/%s@%s/%s'%(user, password, host, service))
        self.cur = self.con.cursor()
        self.sql_query=""
        self.folder=folder
        self.result=[]
        self.historical_queries=[]
        self.hex_dig=""
        self.clear_results=clear_results
    
    def __exit__(self):
        message_text = "Closing connection to Oracle"
        log_message(message_text)
        if(self.clear_results):
            self.clear_saved_results()
        self.cur.close()
        self.con.close()
    
    def clear_saved_results(self):
        i=1
        for hex_dig in list(set(self.historical_queries)):
            pipe = Popen("rm %s/input_data/%s.csv"%(self.folder,hex_dig), shell=True, stdout=PIPE).stdout
            i=i+1
        message_text = "Cleared %s intermediate files" %i
        log_message(message_text)
        
    def execute(self, query="", clear_after_run=False):
        self.query=query
        self.cur.execute(self.query)
        if(clear_after_run):
            self.historical_queries.append(self.hex_dig)
        
    def retrieve_result(self):
        yield self.cur
        
    def save_result(self):
        with open('%s/input_data/%s.csv'%(self.folder,self.hex_dig),'w') as out_file:
            pickle.dump(self.result,out_file)
        
    def get_result(self,query="", hex_dig="",save=False):
        self.query=query
        self.result=[]
        self.hex_dig=hex_dig
        matches=glob.glob('%s/input_data/%s.csv'%(self.folder, self.hex_dig))
        if(len(matches)!=0):
            with open('%s/input_data/%s.csv'%(self.folder,self.hex_dig),'r') as in_file:
                message_text = "Found existing results' file: %s.csv"%self.hex_dig
                log_message(message_text)
                self.result=pickle.load(in_file)
                save=False
            message_text = "Found saved results, records in result: %s"%len(self.result)
            log_message(message_text)
        if(len(self.result)==0):
            self.execute(query=self.query)
            for i in self.retrieve_result().next():
                self.result.append(i)
            message_text = "No saved results found, records from query: %s"%len(self.result)
            log_message(message_text)

        if(save):
            self.save_result(self.hex_dig)

        return list(self.result)

class Queries(object):
    def __init__(self):
        self.query=""
        self.histocial_queries=[]

    def static_panelists(self,week_end='1910'):
        self.query='''select distinct CONSUMER_DIM_KEY 
                      from wh_pnl_synd_p1.proj_fact 
                      where 
                      proj_dim_key in 
                      (select distinct (proj_dim_key) 
                      from wh_pnl_synd_p1.proj_dim 
                      where 
                      survey_type_key = '1740735' and 
                      vg_proj_key = '16729' and 
                      static_length = '52' and 
                      static_end_wk = \'%s\') 
                      order by consumer_dim_key'''%week_end
        return self.query

    def const_IDK_PID_UNITS(self,cat='',brand='',sub_cat="",week_start='',week_end=''):        
        q_category=cat
        q_brand=brand
        q_type=sub_cat
        q_week_start=week_start
        q_week_end=week_end
        if(len(sub_cat)==0):
            self.query='''select * from
            (select distinct(ALLUPC.ITEM_DIM_KEY),
                            A0.CATEGORY,
                            A2.TYPE,
                            TRANS.PANID,
                            TRANS.UNITS
              from WH_DIM_P1.IT_ATR_SYNDRTLR_18935 ALLUPC
            inner join
            (select distinct(ITEM_DIM_KEY), VALUE as CATEGORY
              from WH_DIM_P1.IT_ATR_SYNDRTLR_18935
              where ATTR_NAME='TSV_CATEGORY') A0
              on ALLUPC.ITEM_DIM_KEY=A0.ITEM_DIM_KEY
            inner join
            (select distinct(ITEM_DIM_KEY), VALUE as BRAND
              from WH_DIM_P1.IT_ATR_SYNDRTLR_18935
              where ATTR_NAME='TSV_BRAND') A1
              on ALLUPC.ITEM_DIM_KEY=A1.ITEM_DIM_KEY
            inner join
            (select distinct(ITEM_DIM_KEY), VALUE as TYPE
              from WH_DIM_P1.IT_ATR_SYNDRTLR_18935
              where ATTR_NAME='TSV_TYPE') A2
              on ALLUPC.ITEM_DIM_KEY=A2.ITEM_DIM_KEY
            inner join
            (select CONSUMER_DIM_KEY as PANID, SALE_QTY as UNITS, IT_DIM_KEY
            from WH_PNL_SYND_P1.IT_SALES_FACT 
            '''
            if(len(q_week_start)!=0 and len(q_week_end)!=0):
                self.query= self.query + ('''where TM_DIM_KEY > %s and TM_DIM_KEY < %s) TRANS
            on ALLUPC.ITEM_DIM_KEY=TRANS.IT_DIM_KEY where ''' %(q_week_start,
                                                          q_week_end))

            if(len(q_brand)!=0):
                self.query = self.query + (''' BRAND = \'%s\' ''' %q_brand)
                if(len(q_category)!=0):
                    self.query = self.query + (''' and ''')
            if(len(q_category)!=0):
                self.query = self.query + (''' CATEGORY = \'%s\''''%q_category)
        else:
            self.query='''select * from
            (select distinct(ALLUPC.ITEM_DIM_KEY),
                            A0.CATEGORY,
                            A2.TYPE,
                            TRANS.PANID,
                            TRANS.UNITS
              from WH_DIM_P1.IT_ATR_SYNDRTLR_18935 ALLUPC
            inner join
            (select distinct(ITEM_DIM_KEY), VALUE as CATEGORY
              from WH_DIM_P1.IT_ATR_SYNDRTLR_18935
              where ATTR_NAME='TSV_CATEGORY') A0
              on ALLUPC.ITEM_DIM_KEY=A0.ITEM_DIM_KEY
            inner join
            (select distinct(ITEM_DIM_KEY), VALUE as BRAND
              from WH_DIM_P1.IT_ATR_SYNDRTLR_18935
              where ATTR_NAME='TSV_BRAND') A1
              on ALLUPC.ITEM_DIM_KEY=A1.ITEM_DIM_KEY
            inner join
            (select distinct(ITEM_DIM_KEY), VALUE as TYPE
              from WH_DIM_P1.IT_ATR_SYNDRTLR_18935
              where ATTR_NAME='TSV_TYPE' and VALUE=\'%s\') A2
              on ALLUPC.ITEM_DIM_KEY=A2.ITEM_DIM_KEY
            inner join
            (select CONSUMER_DIM_KEY as PANID, SALE_QTY as UNITS, IT_DIM_KEY
            from WH_PNL_SYND_P1.IT_SALES_FACT 
            '''%sub_cat
            if(len(q_week_start)!=0 and len(q_week_end)!=0):
                self.query= self.query + ('''where TM_DIM_KEY >= %s and TM_DIM_KEY <= %s) TRANS
            on ALLUPC.ITEM_DIM_KEY=TRANS.IT_DIM_KEY ''' %(q_week_start,
                                                          q_week_end))

            if(len(q_brand)!=0):
                self.query = self.query + (''' where BRAND = \'%s\' ''' %q_brand)
                if(len(q_category)!=0):
                    self.query = self.query + (''' and ''')
            if(len(q_category)!=0):
                if(len(q_brand)==0):
                    self.query + (" where ")
                self.query = self.query + (''' CATEGORY = \'%s\''''%q_category)
        self.query = self.query + (''' ) ''')
        self.histocial_queries = self.query + (self.query)
        message_text= self.query
        log_message(message_text,verbose=False)
        return self.query, ["ITEM_DIM_KEY",
                            "CATEGORY",
                            "SUB_CATEGORY",
                            "PANID",
                            "UNITS"]

def dummy_coding(x,col_names):
    sep={}
    for col in col_names:
        vals=list(x[col].unique())
        for val in vals:
            sep["%s_%s"%(col,val)] = (x[col]==val).astype(int)
    return sep

def gen_hash(category, sub_category, brand, week_start, week_end):
    key=""
    value=""
    if(len(sub_category)>0):
        key="sub_category"
        value=sub_category
    elif(len(brand)>0):
        key="brand"
        value=brand
    else:
        key="category"
        value=brand
    value=value.replace("/","-")
    value=value.replace(" ","_")
    return "%s-%s-%s-%s"%(key,value,week_start,week_end)

def sum_transactions(results,columns):
    df=pd.DataFrame(results,columns=columns)
    def x_sum(x):
        return pd.Series({"UNITS":np.sum(x.UNITS)})
    result=df.groupby("PANID").apply(x_sum)
    result.reset_index(inplace=True)
    return result

def calc_x(x):
    if x>900000000:
        return x-900000000
    else:
        return x

def build_r_model(folder, file_name, threshold):
    r = pr.R(use_pandas="True")
    r("library(glmnet)")
    r("library(data.table)")
    r('beg_time <- Sys.time()')
    r('RDA <- fread("%s/r-data/%s.csv")'%(folder,file_name))
    r('end_time <- Sys.time()-beg_time')
    message_text= "Completed reading file into R in: %ss"%(r.get('end_time'))
    log_message(message_text)
    r("library(doMC)")
    r("registerDoMC(cores=10)")
    r("set.seed(1234)")
        
    r('df<-as.data.frame(RDA)')
    r('beg_time <- Sys.time()')
    r('DEPS<-cbind(df$UNITS_x+1,df$UNITS_y+1)')
    r('DEPS<-log(DEPS)')
    r('drops<-c("UNITS_x","UNITS_y","legacy_pan_id")')
    r('X_ <- data.matrix(df[, !(names(df) %in% drops)])')

    r('my_glm <- cv.glmnet(x=X_,y=DEPS,family="mgaussian",nfolds=10,parallel=TRUE,thresh=%s)'%threshold)
    r('end_time <- Sys.time()-beg_time')
    message_text= "Model built in: %s mins" %r.get('end_time')
    log_message(message_text)
    r('my_predict <-predict(my_glm,newx=X_)')
    r('my_predict <- my_predict[,1,]')
    r('AUC <- cbind( exp(DEPS[,1])-1,exp(my_predict)-1)')
    r('colnames(AUC) <- c("Actual","Predicted")')
    r('AUC <- AUC[order(AUC[,"Predicted"],decreasing=TRUE),]')
    r('auc <- mean(cumsum(AUC[,"Actual"])/sum(AUC[,"Actual"]))')
    message_text= "AUC: %s"%round(r.get('auc'),5)
    log_message(message_text)
    auc=int(round(r.get('auc'),5)*100000)
    r('my_glm.diag.auc<-auc')
    r('my_glm.diag.time<-end_time')
    r('my_glm.diag.nzero<-my_glm$nzero')
    r('save(my_glm,file="%s/r-output/%s-%s.Rdata")'%(folder,file_name,auc))
    r('pdf("%s/r-output/%s-%s.pdf")'%(folder,file_name,auc))
    r('plot(my_glm)')
    r('dev.off()')
    train_set=pd.read_csv('%s/r-data/%s.csv'%(folder,file_name))
    return (auc,int(np.sum(train_set.UNITS_x)),int(np.sum(train_set.UNITS_y)))

def get_r_model(folder,file_name,threshold):
        auc=build_r_model(folder,file_name,threshold)
        return auc

def build_model(category, sub_category, brand, week_start, week_end, use_static, no_debug, threshold = '0.001'):

    message_text= "Getting transactions from Exadata"
    log_message(message_text)
    start= time.time()
    file_name= gen_hash(category,
                    sub_category,
                    brand,
                    week_start,
                    week_end)

    sql = SQLDevel(db_user,db_pwd,folder)
    queries = Queries()
    results=[]
    query1, columns = queries.const_IDK_PID_UNITS(cat=category,brand=brand,sub_cat=sub_category,week_start=week_start,week_end=week_end)
    message_text = "Querying ILD for %s %s %s transactions"%(category, sub_category, brand)
    log_message(message_text)
    results=sql.get_result(query=query1,hex_dig=file_name)



    if(len(results)<=0):
        message_text ="No data found"
        log_message(message_text)
        return (0,0,0)
    else:
        is_category=False

        if(len(brand)>0):
            sub_category=results[0][2]
            message_text= "sub_category is: %s"%sub_category
            log_message(message_text)
            category=''
        elif(len(sub_category)>0):
            category=results[0][1]
            message_text= "category is: %s"%category
            log_message(message_text)
            brand=''
            sub_category=''
        else:
            is_category=True
    
        unit=sum_transactions(results,columns)
        message_text="Panelists with transactions for given time period: %s"%unit.shape[0]
        log_message(message_text)

        query2, columns = queries.const_IDK_PID_UNITS(cat=category,brand=brand,sub_cat=sub_category,week_start=week_start,week_end=week_end)

        hex_dig= gen_hash(category,
                          sub_category,
                          brand,
                          week_start,
                          week_end)
        if(is_category == False):
            message_text = "Querying ILD for %s %s transactions"%(category, sub_category)
            log_message(message_text)
            results=sql.get_result(query=query2,hex_dig=hex_dig)
            unit2=sum_transactions(results,columns)
            result=pd.merge(left=unit,right=unit2,left_on="PANID",right_on="PANID",how="right")
            message_text="Panelists with transactions for given time period: %s"%unit2.shape[0]
            log_message(message_text)
        else:
            result = unit
        static_query=queries.static_panelists(str(int(week_end)-1))
        columns=['CONSUMER_DIM_KEY']
        static_results=sql.get_result(static_query)
        df_static=pd.DataFrame(static_results,columns=columns)
        sql.__exit__()
        sql=[]
        queries=[]
        query=[]
        results=[]
        df=[]
        gc.collect()
        message_text = "Received and rolled up all transactions in: %ss"%(time.time()-start)
        log_message(message_text,folder)

        message_text="Reading in demographics (panelists)"
        log_message(message_text)
        demo_data=pd.read_csv('%s/input_data/dummy_coded_panelists_cleaned.csv'%folder) 

        if(is_category):
            result["UNITS_x"]=result.UNITS
            result["UNITS_y"]=result.UNITS
            result.drop("UNITS",axis=1,inplace=True)

        message_text = "Joining transactions with demographics (panelists)"
        log_message(message_text)

        pan_id_trans = pd.read_csv("/lddata/us/dim/prd/panel/iri/V20.0/%s/CWB_Consumer_Key_Translation_%s.dat"%(week_end,week_end),sep="|",)
        pan_id_trans.columns=['consumer_dim_key','country_code','pan_id']
        pan_id_trans["legacy_pan_id"]=pan_id_trans.pan_id.apply(calc_x)

        if(use_static):
            pan_id_trans = pd.merge(df_static,pan_id_trans,left_on="CONSUMER_DIM_KEY",right_on="consumer_dim_key",how="inner")
            pan_id_trans = pan_id_trans[["consumer_dim_key","country_code","pan_id","legacy_pan_id"]]
            message_text="Applied static"
            log_message(message_text)

        merged_unit=pd.merge(left=result,right=pan_id_trans,left_on='PANID',right_on='consumer_dim_key',how='inner')
        merged_unit.drop(["PANID","consumer_dim_key","country_code","pan_id"],axis=1,inplace=True)
        merged=pd.merge(left=merged_unit,right=demo_data,right_on="IND001607",left_on="legacy_pan_id",how="right")
        merged["legacy_pan_id"] = merged.IND001607
        result=[]
        gc.collect()

        cols_to_keep = list(merged.columns)

        cols_to_keep.remove("IND000001")
        cols_to_keep.remove("IND000040")
        cols_to_keep.remove("IND000097")
        cols_to_keep.remove("IND000106")
        cols_to_keep.remove("IND000115")
        cols_to_keep.remove("IND000124")
        cols_to_keep.remove("IND000133")
        cols_to_keep.remove("IND000142")
        cols_to_keep.remove("IND000151")
        cols_to_keep.remove("IND001607")

        start= time.time()
        message_text = "Writing prepared data to disk: %s/r-data/%s.csv"%(folder,file_name)
        log_message(message_text)
        X=merged[cols_to_keep].fillna(value=0)
        X.to_csv("%s/r-data/%s.csv"%(folder,file_name),index=False)
        demo_data=[]
        merged=[]
        pan_id_trans=[]
        gc.collect()

        message_text = "Wrote prepared data to disk in: %ss"%(time.time()-start)
        log_message(message_text)
        message_text = "Starting model build process"
        log_message(message_text)
        auc = (get_r_model(folder,file_name,threshold),int(np.sum(X.UNITS_x)),int(np.sum(X.UNITS_y)))
        if(no_debug):
            pipe = Popen("rm %s/r-data/%s.csv"%(folder,file_name), shell=True, stdout=PIPE).stdout
        return auc

def score(file_name, model_name, folder):
    model_name=model_name.replace('-','_')
    start= time.time()
    r = pr.R(use_pandas="True")
    r("library(glmnet)")
    r('db_name <- "proscores_results"')
    r('table_name <- "%s"'%model_name)
    r('model_name <- "%s"'%file_name)
 
    r('SQL_Start <- paste("create database if not exists ",db_name," location \'/analytic_users/proscores/",db_name,"\'; use ",db_name," ; create table if not exists ",db_name,".",table_name," as select IND000001 as experian_id,", sep="")')
 
    r('''GetSQLStatement <- function() {
       load(model_name)
       my_coef <- coef(my_glm)
       if(is.list(my_coef)) {
         my_names <- names(my_coef)
         coef_names <- unlist(lapply(my_coef,rownames)[length(my_coef)])
         lcoef <- lapply(my_coef,as.numeric)
         my_coef <- as.matrix(unlist(lcoef[length(lcoef)]))
         row.names(my_coef)<- coef_names
        }
   
        nmes <- row.names(my_coef)[as.vector(my_coef)!=0][-1]
        nmes <- gsub(".","_",nmes,fixed=TRUE)
        vals <- (as.double(my_coef)[as.vector(my_coef)!=0][-1])
        intercept <- (as.double(my_coef)[as.vector(my_coef)!=0][1])
        WithSelect <-paste(SQL_Start," exp(",intercept,"+",paste(vals,nmes,sep="*",collapse="+"),") - 1 as ",gsub(".","_","score",fixed=TRUE),"",sep="")
        return(WithSelect)
      }''')
 
    r('Final_SQL <- paste(GetSQLStatement()," from proscores.demographics ;",sep="")')
    r('write.table(Final_SQL,"%s/score.hql",row.names=FALSE,col.names=FALSE,quote=FALSE)'%folder)
    pipe = Popen("hive -S -f %s/score.hql"%folder, shell=True, stdout=PIPE)
    try:
        while(pipe.poll()!=0):
            pass
        message_text = "Scored proscores_results.%s in: %ss"%(model_name,time.time()-start)
        log_message(message_text)
        return True
    except:
        return False

def main(category, sub_category, brand, two_year, predict, end_week='', no_debug=True, use_static= True, db_u="mspra", db_p=base64.b64decode("UGFzc3cwcmQ="),threshold='0.001'):
    global db_user
    global db_pwd

    ts=time.localtime()
    timestamp="%s-%s-%s_%s:%s:%s" %(ts.tm_year,
                                    ts.tm_mon,
                                    ts.tm_mday,
                                    ts.tm_hour,
                                    ts.tm_min,
                                    ts.tm_sec)

    db_user=db_u
    db_pwd=db_pwd
    message_text = "Starting Application"
    week_end=log_message(message_text,return_iri_week=True)
    if(len(end_week)>0):
        week_end= end_week
    week_start=week_end-52
    if(two_year):
        week_start=week_end-104
    file_name= gen_hash(category,
                        sub_category,
                        brand,
                        "%s"%week_start,
                        "%s"%week_end)

    matches=glob.glob('%s/r-output/%s*.Rdata'%(folder, file_name))
    auc=0
    if(len(matches)==0):
    	matches=glob.glob('%s/r-data/%s*.csv'%(folder, file_name))
    	if(len(matches)!=0):
    		message_text="Found saved training dataset %s"%matches[0]
    		log_message(message_text)
    		tup=get_r_model(folder,matches[0].split('/')[-1].split('.')[0],threshold)
    	else:
            message_text = "No models found. Building for week range: %s - %s"%(week_start,week_end)
            log_message(message_text)

            tup=build_model(category,
                            sub_category,
                            brand,
                            "%s"%week_start,
                            "%s"%week_end,
                            use_static,
                            no_debug,
                            threshold)
        key=""
        value=""
        if(len(brand)>0):
            key="brand"
            value=brand
        elif(len(sub_category)>0):
            key="sub_category"
            value=sub_category
        else:
            key="category"
            value=category
        matches=glob.glob('%s/model-audit.log'%folder)
        if(len(matches)>0):
        	fileout=open(matches[0],'a')
        else:
        	fileout=open('%s/model-audit.log'%folder,'w')
        	header="model-created-on,type,name,start_week,end_week,auc,transactions,parent-level-transactions\n"
        	fileout.writelines(header)
        model_audit_log="%s,%s,%s,%s,%s,%s,%s,%s\n"%(timestamp,key,value,week_start,week_end,tup[0],tup[1],tup[2])
        fileout.writelines(model_audit_log)
        fileout.close()
    else:
    	message_text = "Found model"
    	log_message(message_text)
        message_text = "file: %s"%matches[0]
        log_message(message_text)
        message_text = "auc: 0.%s"%(matches[0].split('-')[-1].split('.')[0])
        log_message(message_text)

    if(predict):
        matches=glob.glob('%s/r-output/%s*.Rdata'%(folder, file_name))
        message_text="Scoring with %s"%matches[0]
        log_message(message_text)
        if(score(matches[0], file_name, folder)):
            pass
        else:
            message_text="Error scoring Experian households"
            log_message(message_text)
    message_text="Exiting application"
    log_message(message_text)


