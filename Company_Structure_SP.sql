CREATE or Replace procedure COMPANY_STRUCTURE_SP as

CURSOR Get_Roots is

select CUSTOMER_KEY ROOT_KEY, decode(PARENT_KEY, NULL,'Y','N') HIGHEST_FLAG,
 CUSTOMER_NAME ROOT_COMPANY
from C
where CURRENT_DESCRIPTION = 'Y';

BEGIN

execute immediate 'truncate table COMPANY_STRUCTURE';

For Roots in Get_Roots 
LOOP
	insert into COMPANY_STRUCTURE 
	(PARENT_KEY,
 	 SUBSIDIARY_KEY,
 	 COMPANY_LEVEL,
 	 SEQUENCE_NUMBER,
 	 LOWEST_FLAG,
 	 HIGHEST_FLAG,
	 PARENT_COMPANY,
 	 SUBSIDIARY_COMPANY)
	select
	  Roots.ROOT_KEY,
	  CUSTOMER_KEY,
	  LEVEL,
	  ROWNUM,
	  'N',
	  Roots.HIGHEST_FLAG,
	  Roots.ROOT_COMPANY,
	  CUSTOMER_NAME
	from
	  CUSTOMER
	 Start with CUSTOMER_KEY = Roots.ROOT_KEY
	 connect by prior CUSTOMER_KEY = PARENT_KEY;
END LOOP;

update COMPANY_STRUCTURE 
   SET LOWEST_FLAG = 'Y'
where not exists (select * from CUSTOMER
where PARENT_KEY = COMPANY_STRUCTURE.SUBSIDIARY_KEY);

COMMIT;
END;  /* of procedure */
