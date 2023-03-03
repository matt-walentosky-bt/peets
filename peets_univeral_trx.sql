
--Peets Coffee Unified Query
--Find the distinct aloha transactions
WITH ae_trx as 
(
select 
LEFT(DATEOFBUSINESS,10) AS DATE,
FKSTOREID AS STOREID, 
CHECKNUMBER,
sum(PRICE) AS PRICE
FROM
RAW_PROD.AE.DPVHSTGNDITEM
WHERE DATEOFBUSINESS = '2023-02-14' 
--AND FKSTOREID = '1096'
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
  STORE_CODE as STOREID,
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
CAST(SPLIT(POSREF,'|')[2] AS INT) AS CHECKNUMBER,
STORENUMBER AS STOREID,
 LEFT(OLOSERVERTIMEUTC,10) AS DATE
from
RAW_PROD.OLO.ORDER_CLOSED_CLEAN
INNER JOIN
RAW_PROD.PTRX.REGISTRATIONS
on 
RAW_PROD.OLO.ORDER_CLOSED_CLEAN.CUSTOMER_EMAIL = RAW_PROD.PTRX.REGISTRATIONS.EMAIL 
WHERE 
  --STORENUMBER = 1096 
  TIMEPLACED LIKE '20230214%' 
),


 --Join together the paytronix loyalty transactions with the aloha transactions
 ae_01 as 
 (
   select 
   distinct ae_trx.*, ptrx_trx.ACCOUNT_ID
   from ae_trx inner join 
   ptrx_trx 
   on 
   cast(AE_TRX.CHECKNUMBER as string) = cast(ptrx_trx.CHECK_NUMBER as string) 
   AND cast(AE_TRX.STOREID as string) = cast(ptrx_trx.STOREID as string)
   AND cast(AE_TRX.DATE as string) = cast(ptrx_trx.DATE as string)
 ),
 
 --Join together the aloha transactions with the order closed clean transactions
 ae_02 as 
 (
  select distinct ae_trx.*, occ_01.ACCOUNT_ID  from ae_trx 
   inner join occ_01 
   on
   CAST(ae_trx.CHECKNUMBER AS STRING) = CAST(occ_01.CHECKNUMBER as string) 
   AND cast(AE_TRX.STOREID as string) = cast(occ_01.STOREID as string)
   AND cast(ae_trx.DATE as string) = cast(occ_01.DATE as string)
 ),
 
 --Union together the two loyalty transactions dataset
 loyal_union as 
 (
 select distinct CHECKNUMBER, DATE, STOREID, PRICE, ACCOUNT_ID from ae_01
 union all
 select distinct CHECKNUMBER, DATE, STOREID, PRICE, ACCOUNT_ID from ae_02
 ),
 
 --Join these with the aloha data
 ae_join as 
 (
  select ae_trx.*, l.account_id from 
 ae_trx
 left join 
 (select distinct CHECKNUMBER, STOREID, DATE, ACCOUNT_ID FROM loyal_union) l
 on cast(ae_trx.CHECKNUMBER as string) = cast(l.CHECKNUMBER as string)
   AND cast(ae_trx.DATE as string) = cast(l.DATE as string)
   AND cast(ae_trx.STOREID as string) = cast(l.STOREID as string)
 ),
 
 --Check to make sure that the account id's actually exist in paytronix registration, some do not
 --Note we are aggregating the account id based on max value, this may not be the best process but need to elimnate a many to one join of account id w/ date, store id, check number
 ae_join_gb
 as 
 
 (
  
   select a.*,b.ptrx_reg
   from 
   (
     select DATE, STOREID, CHECKNUMBER, ACCOUNT_ID, PRICE FROM ae_join 
   ) a
   left join
   (select distinct 1 as ptrx_reg, ACCOUNT_ID FROM RAW_PROD.PTRX.REGISTRATIONS) b
   on a.ACCOUNT_ID = b.ACCOUNT_ID 

 ),
  
 ptrx_reg as 
(
  
select 
  A.ACCOUNT_ID,
  A.FIRST_NAME,
  A.LAST_NAME,
  A.EMAIL,
  A.POSTAL_CODE,
  A.EMAIL_OPT_IN,
  A.PUSH_OPT_IN,
  A.SMS_OPT_IN,
  A.SMS_OPT_IN_VERIFIED
  FROM 
  (SELECT ACCOUNT_ID, MAX(_FILE_ROW_NUMBER) AS MAX_RECORD FROM RAW_PROD.PTRX.REGISTRATIONS GROUP BY ACCOUNT_ID ) MAX_ROW_DATA
  JOIN
  (SELECT * FROM RAW_PROD.PTRX.REGISTRATIONS) A
  ON 
  A._FILE_ROW_NUMBER = MAX_ROW_DATA.MAX_RECORD and A.ACCOUNT_ID = MAX_ROW_DATA.ACCOUNT_ID
),

shopify as 
(
  SELECT
  DISTINCT
  ID as TRX_ID,
  CUSTOMERID,
  CUSTOMERFIRSTNAME,
  CUSTOMERLASTNAME,
  EMAIL,
  TOTALPRICE,
  LEFT(PROCESSEDAT,10) AS DATE,
  'Shopify' as DATA_SOURCE
  FROM
  RAW_PROD.SHOPIFY.ORDERS
  where LEFT(PROCESSEDAT,10) = '2022-02-14' 
),

shopify_paytronix_join as 
(
  SELECT
  shopify.TRX_ID,
  shopify.CUSTOMERID,
  shopify.CUSTOMERFIRSTNAME,
  shopify.CUSTOMERLASTNAME,
  shopify.EMAIL,
  shopify.TOTALPRICE,
  shopify.DATE,
  shopify.DATA_SOURCE,
  ptrx_reg.ACCOUNT_ID,
  ptrx_reg.FIRST_NAME,
  ptrx_reg.LAST_NAME,
  ptrx_reg.POSTAL_CODE
  FROM shopify
  LEFT JOIN
  ptrx_reg
  ON CAST(shopify.EMAIL AS STRING) = CAST(ptrx_reg.EMAIL AS STRING)
),
shopify_ae_union as
(
select 
DATE,
CONCAT(DATE,STOREID,CHECKNUMBER) AS TRX_ID,
ACCOUNT_ID,  
PRICE AS TRX_COST,
CASE WHEN ACCOUNT_ID IS NOT NULL THEN TRX_COST ELSE 0 END AS PTRX_COST,
CASE WHEN ACCOUNT_ID IS NOT NULL THEN 1 ELSE 0 END AS PAYTRONIX_TRX,  
'AE' as DATA_SOURCE
from
ae_join_gb  
union all
select  
DATE,
CAST(TRX_ID AS STRING) AS TRX_ID,  
ACCOUNT_ID,
TOTALPRICE AS TRX_COST,
CASE WHEN ACCOUNT_ID IS NOT NULL THEN TRX_COST ELSE 0 END AS PTRX_COST,
CASE WHEN ACCOUNT_ID IS NOT NULL THEN 1 ELSE 0 END AS PAYTRONIX_TRX,  
DATA_SOURCE
from
shopify_paytronix_join    
)

SELECT
DATE,
DATA_SOURCE,
COUNT(DISTINCT TRX_ID) AS TRXS,
SUM(PAYTRONIX_TRX) AS PTRX_TRXS,
SUM(PAYTRONIX_TRX)/COUNT(DISTINCT TRX_ID) AS fraction
FROM
shopify_ae_union
GROUP BY DATA_SOURCE, DATE
