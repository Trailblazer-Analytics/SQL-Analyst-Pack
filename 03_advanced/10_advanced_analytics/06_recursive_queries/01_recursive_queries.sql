/*
Title: Recursive Queries and Hierarchical Data
Author: Alexander Nykolaiszyn
Created: 2025-06-22
Description: Examples of recursive CTEs, hierarchical queries, and graph algorithms in SQL
*/

-- ==========================================
-- INTRODUCTION TO RECURSIVE QUERIES
-- ==========================================
-- Recursive queries allow you to work with hierarchical and graph-structured data.
-- Common Table Expressions (CTEs) with the RECURSIVE keyword are the standard approach.

-- ==========================================
-- 1. SETTING UP EXAMPLE DATA
-- ==========================================

-- Employee hierarchy table
CREATE TABLE IF NOT EXISTS employees (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    title VARCHAR(100) NOT NULL,
    manager_id INT,
    department VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

-- Insert sample data
INSERT INTO employees (employee_id, name, title, manager_id, department, hire_date, salary)
VALUES
    (1, 'John Smith', 'CEO', NULL, 'Executive', '2010-01-15', 250000.00),
    (2, 'Sarah Johnson', 'CTO', 1, 'Technology', '2012-03-10', 220000.00),
    (3, 'Michael Williams', 'CFO', 1, 'Finance', '2013-05-20', 220000.00),
    (4, 'James Brown', 'VP Engineering', 2, 'Technology', '2014-08-15', 180000.00),
    (5, 'Patricia Davis', 'VP Product', 2, 'Product', '2015-02-12', 180000.00),
    (6, 'Robert Miller', 'Senior Developer', 4, 'Technology', '2016-06-01', 150000.00),
    (7, 'Linda Wilson', 'Senior Developer', 4, 'Technology', '2017-04-15', 150000.00),
    (8, 'David Moore', 'Developer', 6, 'Technology', '2018-09-01', 120000.00),
    (9, 'Elizabeth Taylor', 'Developer', 6, 'Technology', '2019-11-15', 120000.00),
    (10, 'Jennifer Anderson', 'Developer', 7, 'Technology', '2020-02-20', 120000.00);

-- File system example table
CREATE TABLE IF NOT EXISTS file_system (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    is_directory BOOLEAN NOT NULL,
    parent_id INT,
    size_bytes BIGINT,
    created_date TIMESTAMP NOT NULL,
    FOREIGN KEY (parent_id) REFERENCES file_system(id)
);

-- Insert sample data
INSERT INTO file_system (id, name, is_directory, parent_id, size_bytes, created_date)
VALUES
    (1, 'Root', TRUE, NULL, NULL, '2023-01-01 00:00:00'),
    (2, 'Documents', TRUE, 1, NULL, '2023-01-01 00:00:00'),
    (3, 'Pictures', TRUE, 1, NULL, '2023-01-01 00:00:00'),
    (4, 'Work', TRUE, 2, NULL, '2023-01-02 00:00:00'),
    (5, 'Personal', TRUE, 2, NULL, '2023-01-02 00:00:00'),
    (6, 'Project1', TRUE, 4, NULL, '2023-01-03 00:00:00'),
    (7, 'Project2', TRUE, 4, NULL, '2023-01-03 00:00:00'),
    (8, 'Vacation', TRUE, 3, NULL, '2023-01-03 00:00:00'),
    (9, 'specification.docx', FALSE, 6, 1024*25, '2023-01-04 00:00:00'),
    (10, 'presentation.pptx', FALSE, 6, 1024*50, '2023-01-04 00:00:00'),
    (11, 'budget.xlsx', FALSE, 7, 1024*15, '2023-01-04 00:00:00'),
    (12, 'notes.txt', FALSE, 5, 1024*1, '2023-01-04 00:00:00'),
    (13, 'beach.jpg', FALSE, 8, 1024*100, '2023-01-04 00:00:00'),
    (14, 'mountains.jpg', FALSE, 8, 1024*120, '2023-01-04 00:00:00');

-- Graph example: City connections
CREATE TABLE IF NOT EXISTS cities (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    population INT NOT NULL
);

INSERT INTO cities (city_id, city_name, country, population)
VALUES
    (1, 'New York', 'USA', 8800000),
    (2, 'Los Angeles', 'USA', 3900000),
    (3, 'Chicago', 'USA', 2700000),
    (4, 'Houston', 'USA', 2300000),
    (5, 'Toronto', 'Canada', 2900000),
    (6, 'Montreal', 'Canada', 1700000),
    (7, 'Vancouver', 'Canada', 675000),
    (8, 'London', 'UK', 8900000),
    (9, 'Manchester', 'UK', 553000),
    (10, 'Liverpool', 'UK', 494000);

CREATE TABLE IF NOT EXISTS flights (
    flight_id INT PRIMARY KEY,
    from_city_id INT NOT NULL,
    to_city_id INT NOT NULL,
    distance_km INT NOT NULL,
    average_duration_minutes INT NOT NULL,
    FOREIGN KEY (from_city_id) REFERENCES cities(city_id),
    FOREIGN KEY (to_city_id) REFERENCES cities(city_id)
);

INSERT INTO flights (flight_id, from_city_id, to_city_id, distance_km, average_duration_minutes)
VALUES
    (1, 1, 2, 3936, 360), -- New York to Los Angeles
    (2, 1, 3, 1190, 150), -- New York to Chicago
    (3, 1, 5, 551, 90),   -- New York to Toronto
    (4, 1, 8, 5572, 420), -- New York to London
    (5, 2, 3, 2802, 240), -- Los Angeles to Chicago
    (6, 2, 4, 2196, 210), -- Los Angeles to Houston
    (7, 2, 7, 1746, 180), -- Los Angeles to Vancouver
    (8, 3, 4, 1514, 165), -- Chicago to Houston
    (9, 3, 5, 703, 105),  -- Chicago to Toronto
    (10, 5, 6, 502, 85),  -- Toronto to Montreal
    (11, 5, 7, 3363, 300), -- Toronto to Vancouver
    (12, 5, 8, 5556, 420), -- Toronto to London
    (13, 8, 9, 302, 60),   -- London to Manchester
    (14, 8, 10, 350, 65),  -- London to Liverpool
    (15, 9, 10, 57, 30);   -- Manchester to Liverpool

-- ==========================================
-- 2. BASIC RECURSIVE CTE - EMPLOYEE HIERARCHY
-- ==========================================

-- Standard recursive CTE to traverse employee hierarchy (PostgreSQL, SQL Server, MySQL 8.0+)
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: start with the CEO (top-level employee with no manager)
    SELECT 
        employee_id, 
        name, 
        title, 
        manager_id,
        0 AS level,
        CAST(name AS VARCHAR(1000)) AS path
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: join employees with their managers
    SELECT 
        e.employee_id, 
        e.name, 
        e.title, 
        e.manager_id,
        eh.level + 1,
        CAST(eh.path || ' > ' || e.name AS VARCHAR(1000))
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT 
    employee_id,
    REPEAT('    ', level) || name AS hierarchical_name,
    title,
    level,
    path
FROM employee_hierarchy
ORDER BY path;

-- Oracle version using CONNECT BY
/*
SELECT 
    employee_id,
    LPAD(' ', 4 * (LEVEL - 1)) || name AS hierarchical_name,
    title,
    LEVEL - 1 AS level,
    SYS_CONNECT_BY_PATH(name, ' > ') AS path
FROM employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY name;
*/

-- ==========================================
-- 3. FINDING ALL SUBORDINATES
-- ==========================================

-- Find all employees under a specific manager
WITH RECURSIVE subordinates AS (
    -- Base case: start with the specified manager
    SELECT 
        employee_id, 
        name, 
        title, 
        manager_id,
        0 AS level
    FROM employees
    WHERE employee_id = 4  -- VP Engineering
    
    UNION ALL
    
    -- Recursive case: join employees with their managers
    SELECT 
        e.employee_id, 
        e.name, 
        e.title, 
        e.manager_id,
        s.level + 1
    FROM employees e
    JOIN subordinates s ON e.manager_id = s.employee_id
)
SELECT 
    employee_id,
    REPEAT('    ', level) || name AS hierarchical_name,
    title,
    level
FROM subordinates
ORDER BY level, name;

-- ==========================================
-- 4. CALCULATING AGGREGATES IN HIERARCHIES
-- ==========================================

-- Calculate the total salary budget for each manager's team
WITH RECURSIVE org_with_subordinates AS (
    -- Base case: include all employees
    SELECT 
        employee_id, 
        name, 
        manager_id,
        salary
    FROM employees
    
    UNION ALL
    
    -- No additional employees to add in the recursive step
    -- This just establishes the CTE as recursive
    SELECT 
        e.employee_id, 
        e.name, 
        e.manager_id,
        e.salary
    FROM employees e
    JOIN org_with_subordinates o ON e.employee_id = o.employee_id
    WHERE 1=0  -- This ensures no rows are added in recursive steps
)
SELECT 
    m.employee_id,
    m.name AS manager_name,
    m.title,
    COUNT(e.employee_id) - 1 AS num_subordinates,
    SUM(e.salary) AS total_team_salary
FROM employees m
LEFT JOIN employees e ON e.manager_id = m.employee_id OR e.employee_id = m.employee_id
GROUP BY m.employee_id, m.name, m.title
ORDER BY num_subordinates DESC;

-- ==========================================
-- 5. FILE SYSTEM TRAVERSAL
-- ==========================================

-- Display the file system as a tree
WITH RECURSIVE file_tree AS (
    -- Base case: start with the root directory
    SELECT 
        id, 
        name, 
        is_directory, 
        parent_id,
        size_bytes,
        0 AS level,
        CAST(name AS VARCHAR(1000)) AS path
    FROM file_system
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- Recursive case: join with child files/directories
    SELECT 
        fs.id, 
        fs.name, 
        fs.is_directory, 
        fs.parent_id,
        fs.size_bytes,
        ft.level + 1,
        CAST(ft.path || '/' || fs.name AS VARCHAR(1000))
    FROM file_system fs
    JOIN file_tree ft ON fs.parent_id = ft.id
)
SELECT 
    id,
    REPEAT('    ', level) || 
    CASE 
        WHEN is_directory THEN '📁 ' 
        ELSE '📄 ' 
    END || name AS hierarchical_name,
    CASE 
        WHEN is_directory THEN 'Directory' 
        ELSE 'File' 
    END AS type,
    path,
    CASE 
        WHEN size_bytes IS NULL THEN NULL
        WHEN size_bytes < 1024 THEN size_bytes || ' B'
        WHEN size_bytes < 1024*1024 THEN ROUND(size_bytes/1024.0, 2) || ' KB'
        ELSE ROUND(size_bytes/(1024.0*1024.0), 2) || ' MB'
    END AS size
FROM file_tree
ORDER BY path;

-- Calculate directory sizes (including subdirectories)
WITH RECURSIVE file_tree AS (
    -- Base case: include all files and directories
    SELECT 
        id, 
        name, 
        is_directory, 
        parent_id,
        size_bytes,
        CAST(name AS VARCHAR(1000)) AS path
    FROM file_system
    
    UNION ALL
    
    -- No additional rows needed for recursive step
    SELECT 
        fs.id, 
        fs.name, 
        fs.is_directory, 
        fs.parent_id,
        fs.size_bytes,
        ft.path
    FROM file_system fs
    JOIN file_tree ft ON fs.id = ft.id
    WHERE 1=0  -- This ensures no rows are added in recursive steps
)
SELECT 
    d.id,
    d.name,
    d.path,
    SUM(f.size_bytes) AS total_size_bytes,
    CASE 
        WHEN SUM(f.size_bytes) < 1024 THEN SUM(f.size_bytes) || ' B'
        WHEN SUM(f.size_bytes) < 1024*1024 THEN ROUND(SUM(f.size_bytes)/1024.0, 2) || ' KB'
        ELSE ROUND(SUM(f.size_bytes)/(1024.0*1024.0), 2) || ' MB'
    END AS total_size
FROM file_system d
JOIN file_tree f ON f.parent_id = d.id OR (f.id = d.id AND f.is_directory = FALSE)
WHERE d.is_directory = TRUE
GROUP BY d.id, d.name, d.path
ORDER BY total_size_bytes DESC;

-- ==========================================
-- 6. GRAPH TRAVERSAL AND PATH FINDING
-- ==========================================

-- Find all possible flight routes between two cities (up to 3 stops)
WITH RECURSIVE flight_routes AS (
    -- Base case: direct flights
    SELECT 
        from_city_id,
        to_city_id,
        ARRAY[from_city_id, to_city_id] AS route,
        1 AS num_flights,
        distance_km,
        average_duration_minutes
    FROM flights
    
    UNION ALL
    
    -- Recursive case: add connecting flights
    SELECT 
        fr.from_city_id,
        f.to_city_id,
        fr.route || f.to_city_id,  -- Append the new destination to the route
        fr.num_flights + 1,
        fr.distance_km + f.distance_km,
        fr.average_duration_minutes + f.average_duration_minutes
    FROM flight_routes fr
    JOIN flights f ON fr.to_city_id = f.from_city_id
    WHERE 
        fr.num_flights < 3  -- Limit to 3 connections
        AND NOT f.to_city_id = ANY(fr.route)  -- Avoid cycles
)
SELECT 
    c1.city_name AS origin,
    c2.city_name AS destination,
    fr.num_flights,
    fr.distance_km,
    fr.average_duration_minutes,
    (SELECT string_agg(c.city_name, ' > ')
     FROM unnest(fr.route) WITH ORDINALITY AS r(city_id, ord)
     JOIN cities c ON c.city_id = r.city_id
     ORDER BY r.ord) AS route_description
FROM flight_routes fr
JOIN cities c1 ON c1.city_id = fr.from_city_id
JOIN cities c2 ON c2.city_id = fr.to_city_id
WHERE 
    fr.from_city_id = 1  -- New York
    AND fr.to_city_id = 10  -- Liverpool
ORDER BY fr.average_duration_minutes;

-- Find the shortest path between two cities (Dijkstra's algorithm simplified)
WITH RECURSIVE shortest_path AS (
    -- Base case: starting point with distance 0
    SELECT 
        from_city_id AS city_id,
        0 AS total_distance,
        0 AS total_duration,
        ARRAY[from_city_id] AS path,
        FALSE AS is_cycle
    FROM flights
    WHERE from_city_id = 1  -- New York
    
    UNION ALL
    
    -- Recursive case: add the next step in the path
    SELECT 
        f.to_city_id,
        sp.total_distance + f.distance_km,
        sp.total_duration + f.average_duration_minutes,
        sp.path || f.to_city_id,
        f.to_city_id = ANY(sp.path)  -- Check for cycles
    FROM shortest_path sp
    JOIN flights f ON sp.city_id = f.from_city_id
    WHERE 
        NOT sp.is_cycle  -- Avoid paths with cycles
        AND array_length(sp.path, 1) < 10  -- Limit path length to avoid infinite recursion
)
SELECT 
    c1.city_name AS origin,
    c2.city_name AS destination,
    sp.total_distance AS distance_km,
    sp.total_duration AS duration_minutes,
    (SELECT string_agg(c.city_name, ' > ')
     FROM unnest(sp.path) WITH ORDINALITY AS r(city_id, ord)
     JOIN cities c ON c.city_id = r.city_id
     ORDER BY r.ord) AS route
FROM shortest_path sp
JOIN cities c1 ON c1.city_id = sp.path[1]
JOIN cities c2 ON c2.city_id = sp.path[array_length(sp.path, 1)]
WHERE 
    sp.city_id = 10  -- Liverpool
    AND NOT sp.is_cycle
ORDER BY sp.total_duration
LIMIT 1;

-- ==========================================
-- 7. ADVANCED: BILL OF MATERIALS (BOM)
-- ==========================================

-- Create BOM tables
CREATE TABLE IF NOT EXISTS products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    unit_price DECIMAL(10, 2) NOT NULL
);

INSERT INTO products (product_id, name, description, unit_price)
VALUES
    (1, 'Bicycle', 'Complete assembled bicycle', 500.00),
    (2, 'Frame', 'Bicycle frame', 200.00),
    (3, 'Wheel', 'Wheel assembly', 50.00),
    (4, 'Handlebar', 'Handlebar assembly', 35.00),
    (5, 'Seat', 'Bicycle seat', 25.00),
    (6, 'Pedals', 'Pair of pedals', 15.00),
    (7, 'Rim', 'Wheel rim', 20.00),
    (8, 'Tire', 'Rubber tire', 15.00),
    (9, 'Tube', 'Inner tube', 5.00),
    (10, 'Spokes', 'Set of spokes', 10.00),
    (11, 'Hub', 'Wheel hub', 12.00),
    (12, 'Brake', 'Brake assembly', 30.00),
    (13, 'Chain', 'Bicycle chain', 18.00),
    (14, 'Gears', 'Gear assembly', 40.00);

CREATE TABLE IF NOT EXISTS product_components (
    parent_product_id INT NOT NULL,
    component_product_id INT NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (parent_product_id, component_product_id),
    FOREIGN KEY (parent_product_id) REFERENCES products(product_id),
    FOREIGN KEY (component_product_id) REFERENCES products(product_id)
);

INSERT INTO product_components (parent_product_id, component_product_id, quantity)
VALUES
    (1, 2, 1),  -- Bicycle has 1 Frame
    (1, 3, 2),  -- Bicycle has 2 Wheels
    (1, 4, 1),  -- Bicycle has 1 Handlebar
    (1, 5, 1),  -- Bicycle has 1 Seat
    (1, 6, 1),  -- Bicycle has 1 Pedals
    (1, 12, 2), -- Bicycle has 2 Brakes
    (1, 13, 1), -- Bicycle has 1 Chain
    (1, 14, 1), -- Bicycle has 1 Gears
    (3, 7, 1),  -- Wheel has 1 Rim
    (3, 8, 1),  -- Wheel has 1 Tire
    (3, 9, 1),  -- Wheel has 1 Tube
    (3, 10, 1), -- Wheel has 1 Spokes
    (3, 11, 1); -- Wheel has 1 Hub

-- Recursive query to get complete BOM for a product
WITH RECURSIVE product_bom AS (
    -- Base case: top-level components
    SELECT 
        p.product_id AS top_product_id,
        pc.component_product_id,
        p2.name AS component_name,
        pc.quantity,
        1 AS level,
        ARRAY[pc.component_product_id] AS component_path
    FROM products p
    JOIN product_components pc ON p.product_id = pc.parent_product_id
    JOIN products p2 ON pc.component_product_id = p2.product_id
    WHERE p.product_id = 1  -- Bicycle
    
    UNION ALL
    
    -- Recursive case: add sub-components
    SELECT 
        pb.top_product_id,
        pc.component_product_id,
        p.name AS component_name,
        pc.quantity * pb.quantity AS quantity,
        pb.level + 1,
        pb.component_path || pc.component_product_id
    FROM product_bom pb
    JOIN product_components pc ON pb.component_product_id = pc.parent_product_id
    JOIN products p ON pc.component_product_id = p.product_id
)
SELECT 
    component_product_id,
    REPEAT('    ', level - 1) || component_name AS hierarchical_component,
    quantity,
    level,
    p.unit_price,
    quantity * p.unit_price AS total_cost
FROM product_bom pb
JOIN products p ON pb.component_product_id = p.product_id
ORDER BY component_path;

-- Calculate the total cost of all components
WITH RECURSIVE product_bom AS (
    -- Base case: top-level components
    SELECT 
        p.product_id AS top_product_id,
        pc.component_product_id,
        pc.quantity,
        1 AS level
    FROM products p
    JOIN product_components pc ON p.product_id = pc.parent_product_id
    WHERE p.product_id = 1  -- Bicycle
    
    UNION ALL
    
    -- Recursive case: add sub-components
    SELECT 
        pb.top_product_id,
        pc.component_product_id,
        pc.quantity * pb.quantity AS quantity,
        pb.level + 1
    FROM product_bom pb
    JOIN product_components pc ON pb.component_product_id = pc.parent_product_id
)
SELECT 
    p1.product_id,
    p1.name,
    p1.unit_price AS selling_price,
    SUM(pb.quantity * p2.unit_price) AS total_component_cost,
    p1.unit_price - SUM(pb.quantity * p2.unit_price) AS profit_margin,
    ROUND(
        (p1.unit_price - SUM(pb.quantity * p2.unit_price)) / p1.unit_price * 100, 
        2
    ) AS profit_percentage
FROM products p1
JOIN product_bom pb ON p1.product_id = pb.top_product_id
JOIN products p2 ON pb.component_product_id = p2.product_id
GROUP BY p1.product_id, p1.name, p1.unit_price;

-- ==========================================
-- 8. CLEANUP (UNCOMMENT TO RUN)
-- ==========================================

-- DROP TABLE IF EXISTS product_components;
-- DROP TABLE IF EXISTS products;
-- DROP TABLE IF EXISTS flights;
-- DROP TABLE IF EXISTS cities;
-- DROP TABLE IF EXISTS file_system;
-- DROP TABLE IF EXISTS employees;
