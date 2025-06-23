/*
Title: XML Data Handling in SQL
Author: Alexander Nykolaiszyn
Created: 2025-06-22
Description: Introduction to working with XML data in SQL across different database platforms
*/

-- ==========================================
-- INTRODUCTION TO XML IN SQL
-- ==========================================
-- XML support in SQL databases predates JSON support and offers powerful capabilities
-- for storing, querying, and manipulating hierarchical data.
-- This script demonstrates common XML operations across different database platforms.

-- ==========================================
-- 1. STORING XML DATA
-- ==========================================

-- SQL Server
CREATE TABLE IF NOT EXISTS product_catalog_mssql (
    product_id INT PRIMARY KEY,
    product_xml XML,
    last_updated DATETIME2 DEFAULT CURRENT_TIMESTAMP
);

-- PostgreSQL
CREATE TABLE IF NOT EXISTS product_catalog_pg (
    product_id INT PRIMARY KEY,
    product_xml XML,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Oracle
-- CREATE TABLE product_catalog_oracle (
--     product_id NUMBER PRIMARY KEY,
--     product_xml XMLTYPE,
--     last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- ==========================================
-- 2. INSERTING XML DATA
-- ==========================================

-- SQL Server
INSERT INTO product_catalog_mssql (product_id, product_xml)
VALUES (
    1,
    '<product>
        <name>Laptop Pro</name>
        <category>Electronics</category>
        <specifications>
            <cpu>Intel i7</cpu>
            <ram>16GB</ram>
            <storage>512GB SSD</storage>
        </specifications>
        <price currency="USD">1299.99</price>
        <tags>
            <tag>laptop</tag>
            <tag>professional</tag>
            <tag>high-performance</tag>
        </tags>
    </product>'
);

-- PostgreSQL
INSERT INTO product_catalog_pg (product_id, product_xml)
VALUES (
    1,
    '<product>
        <name>Laptop Pro</name>
        <category>Electronics</category>
        <specifications>
            <cpu>Intel i7</cpu>
            <ram>16GB</ram>
            <storage>512GB SSD</storage>
        </specifications>
        <price currency="USD">1299.99</price>
        <tags>
            <tag>laptop</tag>
            <tag>professional</tag>
            <tag>high-performance</tag>
        </tags>
    </product>'
);

-- ==========================================
-- 3. QUERYING XML DATA
-- ==========================================

-- SQL Server - Extract values using XQuery
SELECT 
    product_id,
    product_xml.value('(/product/name)[1]', 'VARCHAR(100)') AS product_name,
    product_xml.value('(/product/price)[1]', 'DECIMAL(10,2)') AS price,
    product_xml.value('(/product/price/@currency)[1]', 'VARCHAR(3)') AS currency
FROM product_catalog_mssql;

-- SQL Server - Extract nested values
SELECT 
    product_id,
    product_xml.value('(/product/specifications/cpu)[1]', 'VARCHAR(100)') AS cpu,
    product_xml.value('(/product/specifications/ram)[1]', 'VARCHAR(100)') AS ram,
    product_xml.value('(/product/specifications/storage)[1]', 'VARCHAR(100)') AS storage
FROM product_catalog_mssql;

-- PostgreSQL - Extract values using XPath
SELECT 
    product_id,
    (xpath('/product/name/text()', product_xml))[1]::TEXT AS product_name,
    (xpath('/product/price/text()', product_xml))[1]::TEXT AS price,
    (xpath('/product/price/@currency', product_xml))[1]::TEXT AS currency
FROM product_catalog_pg;

-- PostgreSQL - Extract nested values
SELECT 
    product_id,
    (xpath('/product/specifications/cpu/text()', product_xml))[1]::TEXT AS cpu,
    (xpath('/product/specifications/ram/text()', product_xml))[1]::TEXT AS ram,
    (xpath('/product/specifications/storage/text()', product_xml))[1]::TEXT AS storage
FROM product_catalog_pg;

-- ==========================================
-- 4. FILTERING XML DATA
-- ==========================================

-- SQL Server - Filter based on XML values
SELECT 
    product_id
FROM product_catalog_mssql
WHERE product_xml.value('(/product/category)[1]', 'VARCHAR(100)') = 'Electronics';

-- SQL Server - Filter with more complex conditions
SELECT 
    product_id
FROM product_catalog_mssql
WHERE 
    product_xml.value('(/product/specifications/cpu)[1]', 'VARCHAR(100)') LIKE '%Intel%'
    AND CAST(product_xml.value('(/product/price)[1]', 'DECIMAL(10,2)') AS DECIMAL(10,2)) > 1000;

-- PostgreSQL - Filter based on XML values
SELECT 
    product_id
FROM product_catalog_pg
WHERE (xpath('/product/category/text()', product_xml))[1]::TEXT = 'Electronics';

-- PostgreSQL - Filter with more complex conditions
SELECT 
    product_id
FROM product_catalog_pg
WHERE 
    (xpath('/product/specifications/cpu/text()', product_xml))[1]::TEXT LIKE '%Intel%'
    AND (xpath('/product/price/text()', product_xml))[1]::TEXT::DECIMAL > 1000;

-- ==========================================
-- 5. WORKING WITH XML COLLECTIONS
-- ==========================================

-- SQL Server - Using nodes() to work with collections
SELECT 
    p.product_id,
    t.tag.value('.', 'VARCHAR(100)') AS tag
FROM 
    product_catalog_mssql p
CROSS APPLY product_xml.nodes('/product/tags/tag') t(tag);

-- PostgreSQL - Using unnest() with xpath to work with collections
SELECT 
    product_id,
    unnest(xpath('/product/tags/tag/text()', product_xml))::TEXT AS tag
FROM product_catalog_pg;

-- ==========================================
-- 6. UPDATING XML DATA
-- ==========================================

-- SQL Server - Update a specific XML element
UPDATE product_catalog_mssql
SET product_xml.modify('
    replace value of (/product/price/text())[1]
    with "1399.99"
')
WHERE product_id = 1;

-- SQL Server - Add a new element
UPDATE product_catalog_mssql
SET product_xml.modify('
    insert <color>Silver</color>
    after (/product/category)[1]
')
WHERE product_id = 1;

-- PostgreSQL - Updating XML is more complex and typically involves reconstructing the XML
-- Here's a simple example of updating the entire XML value
UPDATE product_catalog_pg
SET product_xml = XMLPARSE(DOCUMENT
    REPLACE(
        product_xml::TEXT, 
        '<price currency="USD">1299.99</price>', 
        '<price currency="USD">1399.99</price>'
    )
)
WHERE product_id = 1;

-- ==========================================
-- 7. XML SCHEMA VALIDATION
-- ==========================================

-- SQL Server - Create an XML Schema Collection
-- CREATE XML SCHEMA COLLECTION ProductSchema AS 
-- N'<?xml version="1.0" encoding="UTF-8"?>
-- <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
--   <xs:element name="product">
--     <xs:complexType>
--       <xs:sequence>
--         <xs:element name="name" type="xs:string"/>
--         <xs:element name="category" type="xs:string"/>
--         <xs:element name="specifications">
--           <xs:complexType>
--             <xs:sequence>
--               <xs:element name="cpu" type="xs:string"/>
--               <xs:element name="ram" type="xs:string"/>
--               <xs:element name="storage" type="xs:string"/>
--             </xs:sequence>
--           </xs:complexType>
--         </xs:element>
--         <xs:element name="price">
--           <xs:complexType>
--             <xs:simpleContent>
--               <xs:extension base="xs:decimal">
--                 <xs:attribute name="currency" type="xs:string"/>
--               </xs:extension>
--             </xs:simpleContent>
--           </xs:complexType>
--         </xs:element>
--       </xs:sequence>
--     </xs:complexType>
--   </xs:element>
-- </xs:schema>';

-- SQL Server - Use the XML Schema Collection
-- CREATE TABLE product_catalog_validated (
--     product_id INT PRIMARY KEY,
--     product_xml XML(DOCUMENT ProductSchema),
--     last_updated DATETIME2 DEFAULT CURRENT_TIMESTAMP
-- );

-- ==========================================
-- 8. ADVANCED XML TECHNIQUES
-- ==========================================

-- SQL Server - FOR XML to generate XML from relational data
SELECT 
    1 AS [@product_id],
    'Laptop Pro' AS [name],
    'Electronics' AS [category],
    (
        SELECT 
            'Intel i7' AS [cpu],
            '16GB' AS [ram],
            '512GB SSD' AS [storage]
        FOR XML PATH('specifications'), TYPE
    ),
    (
        SELECT '1299.99' AS [@amount], 'USD' AS [@currency]
        FOR XML PATH('price'), TYPE
    ),
    (
        SELECT tag AS '*'
        FROM (VALUES ('laptop'), ('professional'), ('high-performance')) AS Tags(tag)
        FOR XML PATH('tag'), ROOT('tags'), TYPE
    )
FOR XML PATH('product');

-- PostgreSQL - XML generation from relational data
SELECT XMLELEMENT(
    NAME product,
    XMLATTRIBUTES(1 AS product_id),
    XMLELEMENT(NAME name, 'Laptop Pro'),
    XMLELEMENT(NAME category, 'Electronics'),
    XMLELEMENT(
        NAME specifications,
        XMLELEMENT(NAME cpu, 'Intel i7'),
        XMLELEMENT(NAME ram, '16GB'),
        XMLELEMENT(NAME storage, '512GB SSD')
    ),
    XMLELEMENT(
        NAME price,
        XMLATTRIBUTES('USD' AS currency),
        '1299.99'
    ),
    XMLELEMENT(
        NAME tags,
        XMLELEMENT(NAME tag, 'laptop'),
        XMLELEMENT(NAME tag, 'professional'),
        XMLELEMENT(NAME tag, 'high-performance')
    )
);

-- ==========================================
-- 9. XML TO RELATIONAL TRANSFORMATION
-- ==========================================

-- SQL Server - Convert XML to relational format using OPENXML
DECLARE @xml XML = (SELECT product_xml FROM product_catalog_mssql WHERE product_id = 1);
DECLARE @handle INT;

EXEC sp_xml_preparedocument @handle OUTPUT, @xml;

SELECT 
    Name,
    Category,
    Price,
    CPU,
    RAM,
    Storage
FROM OPENXML(@handle, '/product', 2)
WITH (
    Name VARCHAR(100) './name',
    Category VARCHAR(100) './category',
    Price DECIMAL(10,2) './price',
    CPU VARCHAR(100) './specifications/cpu',
    RAM VARCHAR(100) './specifications/ram',
    Storage VARCHAR(100) './specifications/storage'
);

EXEC sp_xml_removedocument @handle;

-- ==========================================
-- BEST PRACTICES
-- ==========================================

-- 1. Consider XML vs. JSON based on your specific requirements and database support
-- 2. Use XML Schema Validation when data structure consistency is critical
-- 3. Leverage XPath and XQuery for efficient querying
-- 4. Index XML columns when they will be frequently queried
-- 5. Be aware of the performance implications of large XML documents
-- 6. Use the appropriate XML data type for your database platform

-- ==========================================
-- CLEANUP (UNCOMMENT TO RUN)
-- ==========================================

-- DROP TABLE IF EXISTS product_catalog_mssql;
-- DROP TABLE IF EXISTS product_catalog_pg;
-- DROP XML SCHEMA COLLECTION IF EXISTS ProductSchema;
