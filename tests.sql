/* Higest parent test */
WITH t AS (
SELECT count(*) actual
FROM company_structure
WHERE Parent_company = 'Pomegranate'
AND highest_parent = 'Y'
)
SELECT CASE actual WHEN 10 THEN 'Pass' ELSE 'Fail' END "Pomegranite on Top" FROM t;

WITH t AS (
SELECT count(*) actual
FROM company_structure
WHERE Parent_company <> 'Pomegranate'
AND highest_parent = 'Y'
)
SELECT CASE actual WHEN 0 THEN 'Pass' ELSE 'Fail' END "No other tops" FROM t;

CREATE OR REPLACE VIEW lowest_subsidiaries AS
    SELECT * from customer
    WHERE parent_key is not null 
    AND customer_key NOT IN (
        SELECT parent_key FROM customer WHERE parent_key is not null
    );

/* Lowest tests */
WITH t AS (
SELECT count(*) actual
FROM company_structure
WHERE subsidiary_key IN (select customer_key from lowest_subsidiaries)
AND lowest_subsidiary = 'Y'
)
SELECT CASE actual WHEN 20 THEN 'Pass' ELSE 'Fail' END "Lowest" FROM t;


WITH t AS (
SELECT count(*) actual
FROM company_structure
WHERE subsidiary_key NOT IN (select customer_key from lowest_subsidiaries)
AND lowest_subsidiary = 'Y'
)
SELECT CASE actual WHEN 0 THEN 'Pass' ELSE 'Fail' END "False Lowest" FROM t;

/* Level test */
WITH t AS (
SELECT count(*) actual
FROM company_structure
WHERE parent_key = subsidiary_key
AND company_level = 1 
AND sequence_number = 1
)
SELECT CASE actual WHEN 10 THEN 'Pass' ELSE 'Fail' END "Self Link properties" FROM t;

WITH t AS (
SELECT count(*) actual
FROM company_structure
WHERE parent_key <> subsidiary_key
AND (company_level = 1 OR sequence_number = 1)
)
SELECT CASE actual WHEN 0 THEN 'Pass' ELSE 'Fail' END "Negated Self Link properties" FROM t;

WITH t AS (
SELECT count(*) actual
FROM company_structure
INNER JOIN customer 
    ON customer.customer_key = company_structure.subsidiary_key
    AND customer.parent_key = company_structure.parent_key
WHERE company_level = 2
)
SELECT CASE actual WHEN 9 THEN 'Pass' ELSE 'Fail' END "Children at level 2" FROM t;

WITH t AS (
SELECT count(*) actual
FROM company_structure
WHERE company_level = 2
AND not exists (
    SELECT 1 FROM customer 
    WHERE customer.customer_key = company_structure.subsidiary_key
    AND customer.parent_key = company_structure.parent_key
    )
)
SELECT CASE actual WHEN 0 THEN 'Pass' ELSE 'Fail' END "All level 2 is a direct child" FROM t;
