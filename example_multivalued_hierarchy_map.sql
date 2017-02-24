/* 
Multi Valued Hierachy map example.  From page 190-195
of _Agile_Data_Warehouse_Design_ https://gumroad.com/l/modelstorming
*/

CREATE TABLE EMPLOYEE
(employee_id INT
,employee_name VARCHAR2(100)
,constraint employee_pk PRIMARY KEY (employee_id)
);

INSERT INTO EMPLOYEE (employee_id,employee_name) 
SELECT 1,'Eve Tasks' FROM dual UNION ALL
SELECT 2,'George Smiley' FROM dual UNION ALL
SELECT 3,'Gerald Mole' FROM dual UNION ALL
SELECT 4,'M' FROM dual UNION ALL
SELECT 5,'Bond' FROM dual UNION ALL
SELECT 6,'Moneypenny' FROM dual;

CREATE TABLE EMPLOYEE_EMPLOYEE 
(employee_id INT 
,manager_id INT
,role_type CHAR(1) NOT NULL
,FTE NUMBER(2,1)
,CONSTRAINT employee_employee_PK PRIMARY KEY (employee_id, manager_id)
,CONSTRAINT employee_employee_fk FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
,CONSTRAINT employee_manager_fk FOREIGN KEY (manager_id) REFERENCES employee(employee_id)
,CONSTRAINT employee_employee_roletype_ck CHECK (role_type IN ('P','T'))
,CONSTRAINT employee_employee_fte_ck CHECK (fte <= 1)
);

INSERT INTO employee_employee (employee_id, manager_id, role_type, fte)
SELECT 2,1,'P',1 FROM dual UNION ALL
SELECT 3,1,'P',1 FROM dual UNION ALL
SELECT 4,3,'P',1 FROM dual UNION ALL
SELECT 5,2,'T',0.2 FROM dual UNION ALL
SELECT 5,4,'P',0.8 FROM dual UNION ALL
SELECT 6,4,'P',0.5 FROM dual UNION ALL
SELECT 6,5,'P',0.5 FROM dual
;

CREATE MATERIALIZED VIEW REPORTING_STRUCTURE AS
WITH employee_reporting AS (
    SELECT employee.employee_id
       ,   employee.employee_name
       ,   employee_employee.manager_id
       ,   employee_employee.fte
       ,CASE WHEN employee_employee.manager_id IS NULL
            THEN 'Y'
            ELSE 'N'
            END
        highest
       ,CASE WHEN EXISTS (
                    SELECT 1
                    FROM employee_employee reportees
                    WHERE reportees.manager_id = employee.employee_id
                )
            THEN 'N'
            ELSE 'Y'
            END
        lowest
        , CASE role_type
        WHEN 'T' THEN 1
        ELSE 0
        END role_type
    FROM employee
    LEFT OUTER JOIN employee_employee
    ON employee_employee.employee_id = employee.employee_id
),hmap (
    manager_id
   ,manager_name
   ,employee_id
   ,employee_name
   ,employee_level
   ,sequence_number
   ,lowest
   ,highest
   ,role_type
   ,fte
) AS (
    SELECT DISTINCT employee_id manager_id
       ,   employee_name manager_name
       ,   employee_id
       ,   employee_name
       ,   1 employee_level
       ,   1 sequence_number
       ,   lowest
       ,   highest
       ,   0 role_type
       ,   1 fte
    FROM employee_reporting
    UNION ALL
    SELECT hmap.manager_id
       ,   hmap.manager_name
       ,   er.employee_id
       ,   er.employee_name
       ,   1 + hmap.employee_level employee_level
       , hmap.sequence_number + (row_number() OVER (PARTITION BY er.manager_id ORDER by er.employee_name)) / power(10,hmap.employee_level) sequence_number
       , er.lowest
       , hmap.highest
       , hmap.role_type + er.role_type
       ,   hmap.fte * er.fte
    FROM employee_reporting er
        INNER JOIN hmap ON hmap.employee_id = er.manager_id
) SELECT 
  manager_id manager_key
 ,manager_name
 ,employee_id employee_key
 ,employee_name
 ,employee_level
 ,sequence_number
 ,lowest lowest_employee
 ,highest highest_manager
 ,CASE role_type
   WHEN 0 THEN 'Permanent'
   ELSE 'Temporary'
  END role_type
 ,fte
FROM hmap
ORDER BY manager_id,sequence_number;


