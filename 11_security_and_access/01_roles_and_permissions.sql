/*
    File: 11_security_and_access/01_roles_and_permissions.sql
    Topic: Security and Access
    Purpose: Demonstrates how to create roles and grant/revoke permissions.
    Author: Trailblazer Analytics
    Created: 2025-06-21
    Updated: 2025-06-21
    SQL Flavors: ✅ PostgreSQL | ✅ MySQL | ✅ SQL Server | ✅ Oracle | ✅ BigQuery | ✅ Snowflake
    Notes:
      • Managing database access is crucial for security.
      • Roles are a way to group permissions and assign them to users.
*/

-- =================================================================================
-- Example: Creating Roles and Managing Permissions
-- =================================================================================

-- Scenario: We want to create a new role for junior analysts who should only have read access to the `customers` table.

-- Step 1: Create a new role.
CREATE ROLE junior_analyst;

-- Step 2: Grant SELECT permission on the `customers` table to the new role.
GRANT SELECT ON customers TO junior_analyst;

-- Step 3: Create a new user and assign them to the `junior_analyst` role.
-- (User creation syntax varies significantly between database systems)

-- POSTGRESQL EXAMPLE
-- CREATE USER bob WITH PASSWORD 'a_secure_password';
-- GRANT junior_analyst TO bob;

-- SQL SERVER EXAMPLE
-- CREATE LOGIN bob WITH PASSWORD = 'a_secure_password';
-- CREATE USER bob FOR LOGIN bob;
-- ALTER ROLE junior_analyst ADD MEMBER bob;

-- Step 4: Revoke a permission from the role.
-- If we later decide junior analysts should not access the `customers` table:
REVOKE SELECT ON customers FROM junior_analyst;

/*
-- Expected Result:
-- A new role `junior_analyst` is created with specific, limited permissions.
-- Users assigned to this role will inherit those permissions.
-- This provides a clean and secure way to manage user access.
*/

-- =================================================================================
-- Expanded Example: Detailed Roles and Permissions Management
-- =================================================================================

-- File: 11_security_and_access/01_roles_and_permissions.sql
-- Topic: Roles and Permissions
-- Author: Gunther Cox
-- Date: 2023-05-29

-- Purpose:
-- This script demonstrates the fundamentals of database security and access control.
-- It covers how to create roles, grant permissions to those roles, and then assign
-- users to roles. This is the standard practice for managing database access securely.

-- Prerequisites:
-- This script is for database administrators. The commands shown here require high-level
-- privileges. The exact syntax for user and role management can vary significantly
-- across different SQL database systems.

-- Dialect Compatibility:
-- - `CREATE ROLE`, `GRANT`, and `REVOKE` are standard SQL commands.
-- - `CREATE USER` and assigning users to roles have dialect-specific syntax.
--   Examples are provided for PostgreSQL and SQL Server.
-- - The Chinook database does not have users to practice on, so this script is for
--   demonstration purposes.

---------------------------------------------------------------------------------------------------

-- Section 1: Why Use Roles?

-- Managing permissions for individual users is tedious and error-prone. If you have 100 users
-- who all need the same access, you would have to run `GRANT` commands 100 times for each table.

-- Roles simplify this by creating a named collection of permissions. You grant permissions
-- to the role, and then you grant the role to users. When a user's job changes, you can
-- simply change their role membership instead of re-doing all their individual permissions.

-- Principle of Least Privilege: Users should only have the minimum permissions necessary
-- to perform their job functions. Roles help enforce this principle effectively.

---------------------------------------------------------------------------------------------------

-- Section 2: Creating Roles and Granting Permissions

-- Scenario: We need to create two roles at the Chinook music store.
-- 1. `junior_analyst`: Can only read (SELECT) data from the `customers` and `invoices` tables.
-- 2. `senior_analyst`: Can read from all tables and can also insert new artists.

-- Step 2.1: Create the roles.
-- The syntax is generally straightforward.
CREATE ROLE junior_analyst;
CREATE ROLE senior_analyst;

-- In some systems like SQL Server, you might need to specify an authorization context.
-- `CREATE ROLE junior_analyst AUTHORIZATION dbo;`

-- Step 2.2: Grant permissions to the `junior_analyst` role.
-- This role gets read-only access to specific tables.
GRANT SELECT ON customers TO junior_analyst;
GRANT SELECT ON invoices TO junior_analyst;

-- Step 2.3: Grant permissions to the `senior_analyst` role.
-- This role gets broader read access and some write access.

-- PostgreSQL / SQL Server:
GRANT SELECT ON ALL TABLES IN SCHEMA public TO senior_analyst;
GRANT INSERT ON artists TO senior_analyst;

-- Note: Granting access to all tables can have different syntax.
-- In MySQL, it might be `GRANT SELECT ON chinook.* TO senior_analyst;`

---------------------------------------------------------------------------------------------------

-- Section 3: Managing Users and Assigning Roles

-- This is the most dialect-specific part of access control.

-- Scenario: We have two employees, Alice (a junior analyst) and Bob (a senior analyst).
-- We need to create user accounts for them and assign them to the appropriate roles.

-- Step 3.1: Create the users.
-- User creation always involves setting up a login mechanism, usually a password.

-- PostgreSQL Example:
-- `CREATE USER alice WITH PASSWORD 'secure_password_for_alice';`
-- `CREATE USER bob WITH PASSWORD 'secure_password_for_bob';`

-- SQL Server Example:
-- `CREATE LOGIN alice WITH PASSWORD = 'secure_password_for_alice';`
-- `CREATE USER alice FOR LOGIN alice;`
-- `CREATE LOGIN bob WITH PASSWORD = 'secure_password_for_bob';`
-- `CREATE USER bob FOR LOGIN bob;`

-- Step 3.2: Assign the roles to the users.

-- PostgreSQL Example:
-- `GRANT junior_analyst TO alice;`
-- `GRANT senior_analyst TO bob;`

-- SQL Server Example:
-- `ALTER ROLE junior_analyst ADD MEMBER alice;`
-- `ALTER ROLE senior_analyst ADD MEMBER bob;`

-- Now, Alice can log in and run `SELECT * FROM customers;` but will get an error if she
-- tries to `SELECT * FROM artists;`. Bob can select from any table and insert into `artists`.

---------------------------------------------------------------------------------------------------

-- Section 4: Revoking Permissions and Roles

-- If an employee's responsibilities change, you may need to revoke permissions or roles.

-- Step 4.1: Revoke a specific permission from a role.
-- Let's say we decide junior analysts should no longer see invoice details.
REVOKE SELECT ON invoices FROM junior_analyst;
-- Any user with the `junior_analyst` role, like Alice, immediately loses this permission.

-- Step 4.2: Revoke a role from a user.
-- If Alice gets promoted, we might remove her from the junior role before adding her to a new one.

-- PostgreSQL Example:
-- `REVOKE junior_analyst FROM alice;`

-- SQL Server Example:
-- `ALTER ROLE junior_analyst DROP MEMBER alice;`

-- Proper use of roles and permissions is the foundation of a secure and well-managed database.
