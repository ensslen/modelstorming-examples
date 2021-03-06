/* Define HV Customer Dimension with Type 2 SCD attribute CURRENT_DESCRIPTION (would also contain Start_Date and End_Date but not needed to prove CV HM solution) */

Create table CUSTOMER (
 CUSTOMER_KEY	     INTEGER NOT NULL,
 CUSTOMER_NAME	     VARCHAR(50),
 CUSTOMER_ID         CHAR(5),
 PARENT_KEY	         INTEGER,
 CURRENT_DESCRIPTION CHAR(1),
 CONSTRAINT CUSTOMER_PK PRIMARY KEY ( CUSTOMER_KEY ),
 CONSTRAINT CUSTOMER_PARENT_FK FOREIGN KEY (PARENT_KEY) REFERENCES CUSTOMER (CUSTOMER_KEY) 
);

/* column order is Customer_key, Customer_name, Customer_ID, Parent_key, Current_Description */
insert into customer values (100,'Pomegranate','C001',NULL,'N');
insert into customer values (106,'Pomegranate','C001',NULL,'Y');
insert into customer values (102,'iSongs Store','C003',106,'Y');
insert into customer values (103,'PicCzar Movies','C004',106,'Y');
insert into customer values (104,'POM Computing','C005',106,'Y');
insert into customer values (110,'PicCzar Movies','C004',106,'Y');
insert into customer values (101,'iPip Design','C002',104,'Y');
insert into customer values (105,'POM Store','C006',104,'Y');
insert into customer values (107,'POMSoft','C007',104,'Y');
insert into customer values (108,'POMStore.co.uk','C008',105,'Y');
insert into customer values (109,'POMStore.com','C009',105,'Y');
/* End example data */


CREATE MATERIALIZED VIEW COMPANY_STRUCTURE 
 AS
 SELECT  CONNECT_BY_ROOT customer_key parent_key,
            customer_key subsidiary_key,
            level company_level,
            row_number() OVER ( PARTITION BY CONNECT_BY_ROOT customer_key ORDER BY SYS_CONNECT_BY_PATH(customer_key, '/')) sequence_number,
            CASE CONNECT_BY_ISLEAF WHEN 1 THEN 'Y' ELSE 'N' END lowest_subsidiary,
            CASE WHEN CONNECT_BY_ROOT parent_key IS NULL THEN 'Y' ELSE 'N' END HIGHEST_PARENT,
            CONNECT_BY_ROOT customer_name parent_company,
            customer_name subsidiary_company
        FROM customer
        WHERE current_description = 'Y'
        CONNECT BY
            PRIOR customer_key = parent_key;