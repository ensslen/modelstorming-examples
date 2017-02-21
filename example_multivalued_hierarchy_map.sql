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
SELECT 6,4,'P',1 FROM dual;

CREATE MATERIALIZED VIEW REPORTING_STRUCTURE 
 AS
 WITH employee_reporting AS (
    SELECT employee.employee_id
        ,employee.employee_name
        ,employee_employee.manager_id
        /* Default values for top of hierarchy */
        ,CASE employee_employee.role_type
            WHEN 'T' THEN 'Temporary'
            ELSE 'Permanent'
            END role_type
        ,coalesce(employee_employee.fte,1) fte
    FROM employee 
    LEFT OUTER JOIN employee_employee 
        ON employee_employee.employee_id = employee.employee_id
)
 SELECT  CONNECT_BY_ROOT employee_id manager_key,
         CONNECT_BY_ROOT employee_name manager_name,
            employee_id employee_key,
            employee_name,
            level employee_level,
            100 * row_number() OVER ( PARTITION BY CONNECT_BY_ROOT employee_id ORDER BY SYS_CONNECT_BY_PATH(employee_id, '/')) sequence_number,
            CASE CONNECT_BY_ISLEAF WHEN 1 THEN 'Y' ELSE 'N' END lowest_employee,
            CASE WHEN CONNECT_BY_ROOT manager_id IS NULL THEN 'Y' ELSE 'N' END highest_manager,
            role_type,
            /* this only appears to work.  Multiple partial weightings need to be multiplied */
            fte weighing_factor
        FROM employee_reporting
        CONNECT BY
            PRIOR employee_id = manager_id;

