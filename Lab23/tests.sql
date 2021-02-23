-----------------------------------------
------------INSERT TESTS-----------------
-----------------------------------------
--TEST 1: register to an unlimited course
--EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('1111111111', 'CCC444');

-- TEST 2: register an already registered student
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('2222222222', 'CCC222'); 

-- TEST 3: register a student in the waiting list
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('2222222222', 'CCC333'); 

-- TEST 4: register a student for a course that he has already passed
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('4444444444', 'CCC111'); 

-- TEST 5: register a student who does not meet all the prerequisites
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('3333333333', 'CCC444');

-- TEST 6: register to a limited course, with available places
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('3333333333', 'CCC111');

-- TEST 7: register to a limited course, that is full
-- EXPECTED OUTCOME: added to WaitingList
INSERT INTO Registrations VALUES ('5555555555', 'CCC222');