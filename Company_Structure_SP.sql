CREATE OR REPLACE PROCEDURE company_structure_sp AS
    CURSOR get_roots IS
        SELECT
            customer_key root_key,
            DECODE(parent_key,NULL,'Y','N') highest_flag,
            customer_name root_company
        FROM
            customer
        WHERE
            current_description = 'Y';

BEGIN
    EXECUTE IMMEDIATE 'truncate table COMPANY_STRUCTURE';
    FOR roots IN get_roots LOOP
        INSERT INTO company_structure (
            parent_key,
            subsidiary_key,
            company_level,
            sequence_number,
            lowest_subsidiary,
            highest_parent,
            parent_company,
            subsidiary_company
        ) SELECT
            roots.root_key,
            customer_key,
            level,
            ROWNUM,
            'N',
            roots.highest_flag,
            roots.root_company,
            customer_name
        FROM
            customer
        START WITH
            customer_key = roots.root_key
        CONNECT BY
            PRIOR customer_key = parent_key;

    END LOOP;

    UPDATE company_structure
        SET
            lowest_subsidiary = 'Y'
    WHERE NOT
        EXISTS (
            SELECT
                *
            FROM
                customer
            WHERE
                parent_key = company_structure.subsidiary_key
        );

    COMMIT;
END company_structure_sp; 