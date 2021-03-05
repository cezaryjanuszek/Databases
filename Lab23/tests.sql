-----------------------------------------
------------INSERT TESTS-----------------
-----------------------------------------
--TEST 1: register to an unlimited course
--EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('4444444444', 'CCC555');

-- TEST 2: register an already registered student
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('2222222222', 'CCC222'); 

-- TEST 3: register a student who is already in a waiting list
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


-----------------------------------------
------------DELETE TESTS-----------------
-----------------------------------------
--TEST 8: unregister from an unlimited course
--EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student='5555555555' AND course='CCC555';

--TEST 9: unregister from an limited course without a waiting list
--EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student='1111111111' AND course='CCC111';

--TEST 10: unregistered from a limited course with a waiting list, when the student is registered;
--EXPECTED OUTCOME: Delete and insert student from waitingList to Registered.
  DELETE FROM Registrations WHERE(student='10' AND course='CCC10');

--TEST 11:unregistered from a limited course with a waiting list, when the student is in the middle of the waiting list;
--EXPECTED OUTCOME: delete from waitingList and change positions.
  DELETE FROM Registrations WHERE(student='12' AND course='CCC11');

--TEST 12:unregistered from an overfull course with a waiting list.
--EXPECTED OUTCOME: Delete from Registered and dont add new student from waitingList;
  DELETE FROM Registrations WHERE(student='10' AND course='CCC12');



