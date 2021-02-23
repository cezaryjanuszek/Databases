--Inspired by the runtests file
-----------------------
-- Delete everything --
-----------------------
\set QUIET true
SET client_min_messages TO WARNING; 

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;

-- Enable log messages again.
SET client_min_messages TO NOTICE; 
\set QUIET false

-----------------------
-- Reload everything --
-----------------------

-- Stop processing files as soon as we find any error.
\set ON_ERROR_STOP on

-- Load files
\i tables.sql
\i inserts.sql
\i views.sql