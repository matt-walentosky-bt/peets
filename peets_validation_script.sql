--Find the distinct aloha transactions
with ae_trx as 
(
select 
LEFT(DATEOFBUSINESS,10) AS DATE,
FKSTOREID, 
CHECKNUMBER,
sum(PRICE) AS PRICE
FROM
RAW_PROD.AE.DPVHSTGNDITEM
WHERE DATEOFBUSINESS = '2023-02-14' 
AND FKSTOREID = '1096'
GROUP BY 
LEFT(DATEOFBUSINESS,10),
FKSTOREID, 
CHECKNUMBER
),
 
--Find the distinct paytronix transactions  ... this is the first part of the loyalty transactions
ptrx_trx as 
(  
  SELECT 
  DISTINCT
  LEFT(TRANSACTION_DATETIME,10) AS DATE,
  --TRANSACTION_DATETIME,
  CHECK_NUMBER,
  STORE_CODE,
  ACCOUNT_ID,
  1 as ptrx_flag
  FROM RAW_PROD.PTRX.TRANSACTIONS 
  where LEFT(TRANSACTION_DATETIME,10) = '2023-02-14'  
),

 --Find the remaining loyal transactions through a join of in RAW_PROD.OLO.ORDER_CLOSED_CLEAN and paytronix registrations
 occ_01 as 
(
select 
POSREF, CUSTOMER_EMAIL as EMAIL, 
RAW_PROD.PTRX.REGISTRATIONS.ACCOUNT_ID,
CAST(SPLIT(POSREF,'|')[2] AS INT) AS CHECKNUMBER
from
RAW_PROD.OLO.ORDER_CLOSED_CLEAN
INNER JOIN
RAW_PROD.PTRX.REGISTRATIONS
on 
RAW_PROD.OLO.ORDER_CLOSED_CLEAN.CUSTOMER_EMAIL = RAW_PROD.PTRX.REGISTRATIONS.EMAIL 
WHERE STORENUMBER = 1096 AND TIMEPLACED LIKE '20230214%' 
),

 
 --Join together the paytronix loyalty transactions with the aloha transactions
 ae_01 as 
 (
   select distinct ae_trx.*, ptrx_trx.ACCOUNT_ID from ae_trx inner join ptrx_trx on 
   AE_TRX.DATE = ptrx_trx.DATE AND cast(AE_TRX.CHECKNUMBER as string) = cast(ptrx_trx.CHECK_NUMBER as string) AND cast(AE_TRX.FKSTOREID as string) = cast(ptrx_trx.STORE_CODE as string)
 ),
 
 --Join together the aloha transactions with the order closed clean transactions
 ae_02 as 
 (
  select distinct ae_trx.*,occ_01.ACCOUNT_ID  from ae_trx 
   inner join occ_01 
   on
   CAST(ae_trx.CHECKNUMBER AS STRING) = CAST(occ_01.CHECKNUMBER as string) 
 ),
 
 
 --Union together the two loyalty transactions dataset
 loyal_union as 
 (
 select distinct CHECKNUMBER, ACCOUNT_ID from ae_01
 union all
 select distinct CHECKNUMBER, ACCOUNT_ID from ae_02
 ),
 
 --Join these with the aloha data
 ae_join as 
 (
   select ae_trx.*, l.account_id from 
 ae_trx
 left join 
 (select distinct CHECKNUMBER, ACCOUNT_ID FROM loyal_union) l
 on cast(ae_trx.CHECKNUMBER as string) = cast(l.CHECKNUMBER as string)
 ),
 
 --Check to make sure that the account id's actually exist in paytronix registration, some do not
 --Note we are aggregating the account id based on max value, this may not be the best process but need to elimnate a many to one join of account id w/ date, store id, check number
 ae_join_gb
 as 
 
 (
   select a.*,b.ptrx_reg
   from 
   (select DATE, FKSTOREID, CHECKNUMBER, MAX(ACCOUNT_ID) AS ACCOUNT_ID, AVG(PRICE) AS PRICE FROM ae_join GROUP BY DATE, FKSTOREID, CHECKNUMBER) a
   left join
   (select distinct 1 as ptrx_reg, ACCOUNT_ID FROM RAW_PROD.PTRX.REGISTRATIONS) b
   on a.ACCOUNT_ID = b.ACCOUNT_ID

 )
 
 
 select * from ae_join_gb;
 
 
