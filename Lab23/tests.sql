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

INSERT INTO Students VALUES ('10', 'Nx', 'ls634', 'Prog2');
INSERT INTO Students VALUES ('11', 'Nx', 'ls623', 'Prog2');
INSERT INTO Students VALUES ('12', 'Nx', 'ls6123', 'Prog2');
INSERT INTO Students VALUES ('13', 'Nx', 'ls6121', 'Prog2');
INSERT INTO Courses VALUES ('CCC10', 'C10', 50,   'Dep1');
INSERT INTO Courses VALUES ('CCC11', 'C11', 50,   'Dep1');
INSERT INTO Courses VALUES ('CCC12', 'C12', 50,   'Dep1');
--10
INSERT INTO LimitedCourses VALUES ('CCC10', 2);
INSERT INTO Registered VALUES('10','CCC10');
INSERT INTO Registered VALUES('11','CCC10');
INSERT INTO WaitingList VALUES ('12', 'CCC10', 1);
--DELETE FROM Registrations WHERE(student='10' AND course='CCC10');
--11
INSERT INTO LimitedCourses VALUES ('CCC11', 1);
INSERT INTO Registered VALUES('10','CCC11');
INSERT INTO WaitingList VALUES ('11', 'CCC11', 1);
INSERT INTO WaitingList VALUES ('12', 'CCC11', 2);
INSERT INTO WaitingList VALUES ('13', 'CCC11', 3);
--DELETE FROM Registrations WHERE(student='12' AND course='CCC11');
--12
INSERT INTO LimitedCourses VALUES ('CCC12', 1);
INSERT INTO Registered VALUES('10','CCC12');
INSERT INTO Registered VALUES('11','CCC12');
INSERT INTO WaitingList VALUES ('13', 'CCC12', 1);
--DELETE FROM Registrations WHERE(student='10' AND course='CCC12');

--TEST 10: unregistered from a limited course with a waiting list, when the student is registered;
--EXPECTED OUTCOME: Delete and insert student from waitingList to Registered.
  DELETE FROM Registrations WHERE(student='10' AND course='CCC10');

--TEST 11:unregistered from a limited course with a waiting list, when the student is in the middle of the waiting list;
--EXPECTED OUTCOME: delete from waitingList and change positions.
  DELETE FROM Registrations WHERE(student='12' AND course='CCC11');

--TEST 12:unregistered from an overfull course with a waiting list.
--EXPECTED OUTCOME: Delete from Registered and dont add new student from waitingList;
  DELETE FROM Registrations WHERE(student='10' AND course='CCC12');






