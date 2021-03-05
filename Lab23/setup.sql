-----------------------
-- Tables --
-----------------------
--departments table
CREATE TABLE Departments(
    name TEXT PRIMARY KEY,
    abbreviation CHAR(6) UNIQUE NOT NULL);

--programs table
CREATE TABLE Programs(
    name TEXT PRIMARY KEY,
    abbreviation CHAR(6) NOT NULL);

--students table
CREATE TABLE Students(
  idnr CHAR(10) PRIMARY KEY,
  name TEXT NOT NULL,
  login CHAR(10) UNIQUE NOT NULL,
  program TEXT NOT NULL,
  CONSTRAINT programChoice UNIQUE (idnr, program),
  FOREIGN KEY (program) REFERENCES Programs(name));

--programindepartment table
CREATE TABLE ProgramInDepartment(
    program TEXT NOT NULL ,
    department TEXT NOT NULL,
    PRIMARY KEY(program, department),
    FOREIGN KEY (program) REFERENCES Programs(name),
    FOREIGN KEY (department) REFERENCES Departments(name));

--branches table
CREATE TABLE Branches (
name TEXT,
program TEXT,
PRIMARY KEY (name,program),
FOREIGN KEY (program) REFERENCES Programs(name));

--Courses table
CREATE TABLE Courses (
code CHAR(6) PRIMARY KEY,
name TEXT NOT NULL,
credits FLOAT NOT NULL,
department TEXT NOT NULL,
CONSTRAINT nonNegative_credits CHECK (credits >= 0),
FOREIGN KEY (department) REFERENCES Departments(name));

--prerequisites table
CREATE TABLE Prerequisites(
code CHAR(6),
prereq_code CHAR(6),
PRIMARY KEY(code, prereq_code),
FOREIGN KEY (code) REFERENCES Courses(code),
FOREIGN KEY (prereq_code) REFERENCES Courses(code));

--LimitedCourses(code, capacity)
CREATE TABLE LimitedCourses(
code CHAR(6) PRIMARY KEY,
capacity INT NOT NULL,
CONSTRAINT capacity_ok CHECK (capacity >= 0),
FOREIGN KEY(code) REFERENCES Courses(code));

--Student branches table
CREATE TABLE StudentBranches (
student CHAR(10) PRIMARY KEY,
branch TEXT NOT NULL,
program TEXT NOT NULL,
FOREIGN KEY (student,program) REFERENCES Students(idnr,program),
FOREIGN KEY (branch,program) REFERENCES Branches);

--Classification table
CREATE TABLE Classifications(
name TEXT PRIMARY KEY );

--Classified courses table
CREATE TABLE Classified (
course CHAR(6),
classification TEXT,
PRIMARY KEY(course,classification),
FOREIGN KEY (course) REFERENCES Courses(code),
FOREIGN KEY (classification) REFERENCES Classifications(name) );

--MandatoryProgram
CREATE TABLE MandatoryProgram(
course CHAR(6) ,
program TEXT,
PRIMARY KEY(course,program),
FOREIGN KEY(course) REFERENCES Courses(code),
FOREIGN KEY(program) REFERENCES Programs(name));

 --Mandatory branch table
 CREATE TABLE MandatoryBranch(
 course CHAR(6),
 branch TEXT,
 program TEXT,
 PRIMARY KEY(course, branch,program),
 FOREIGN KEY (course) REFERENCES Courses(code),
 FOREIGN KEY (branch,program) REFERENCES Branches );

 --Recommended branch table
 CREATE TABLE RecommendedBranch(
  course CHAR(6),
  branch TEXT,
  program TEXT,
  PRIMARY KEY(course, branch,program),
  FOREIGN KEY (course) REFERENCES Courses(code),
  FOREIGN KEY (branch,program) REFERENCES Branches );

--Registered(student, course)
 CREATE TABLE Registered(
  student CHAR(10),
  course CHAR(6),
  PRIMARY KEY(student,course),
  FOREIGN KEY(student) REFERENCES Students(idnr),
  FOREIGN KEY(course) REFERENCES Courses(code));

 --Taken courses table
 CREATE TABLE Taken(
 student CHAR(10),
 course CHAR(6),
 grade CHAR(1) NOT NULL,
 CONSTRAINT grade_ok CHECK (grade IN ('U','3','4','5')),
 PRIMARY KEY (student,course),
 FOREIGN KEY (student) REFERENCES Students(idnr),
 FOREIGN KEY (course) REFERENCES Courses(code) );

--Waiting list table
CREATE TABLE WaitingList (
student CHAR(10),
course CHAR(6),
position INT NOT NULL,
PRIMARY KEY (student, course),
CONSTRAINT course_position UNIQUE(course, position),
FOREIGN KEY (student) REFERENCES Students(idnr),
FOREIGN KEY (course) REFERENCES LimitedCourses(code) );


-----------------------
-- Views --
-----------------------

--View BasicInformation(idnr, name, login, program, branch)
CREATE VIEW BasicInformation AS
 (SELECT Students.idnr,Students.name,Students.login,Students.program,StudentBranches.branch
  FROM Students LEFT JOIN StudentBranches ON  Students.idnr=StudentBranches.student);

--View FinishedCourses(student, course, grade, credits)
CREATE VIEW FinishedCourses AS
 (SELECT Taken.student,Taken.course,Taken.grade,Courses.credits
  FROM Taken INNER JOIN Courses ON Taken.course=Courses.code);

--View PassedCourses(student, course, credits)
CREATE VIEW PassedCourses AS
 (SELECT student,course,credits FROM FinishedCourses WHERE grade IN('3','4','5'));


--View Registrations(student, course, status)
CREATE VIEW Registrations AS
 ((SELECT student, course, 'registered' AS status
 FROM Registered)
 UNION
 (SELECT student, course, 'waiting' AS status
 FROM WaitingList));

 --View UnreadMandatory


CREATE VIEW UnreadMandatory AS
WITH StudentMandatory AS
  (SELECT Students.idnr as student,MandatoryProgram.course FROM Students RIGHT OUTER JOIN MandatoryProgram ON Students.program=MandatoryProgram.program
  UNION
  SELECT StudentBranches.student,MandatoryBranch.course
  FROM StudentBranches INNER JOIN MandatoryBranch USING(branch,program))
SELECT student,course FROM StudentMandatory EXCEPT (SELECT student, course FROM PassedCourses);


--View path to graduation
CREATE VIEW PathToGraduation AS
WITH
  TotalCredits AS
    (SELECT student, SUM(credits) AS total_credits FROM PassedCourses GROUP BY student),
  MandatoryLeft AS
    (SELECT UnreadMandatory.student AS student, COUNT(*) AS mandatory_count FROM UnreadMandatory GROUP BY student),
  MathCredits AS
    (SELECT PassedCourses.student AS student ,SUM(PassedCourses.credits) AS math_credits
      FROM PassedCourses INNER JOIN Classified ON PassedCourses.course=Classified.course
      WHERE(Classified.classification='math') GROUP BY student),
  ResearchCredits AS
    (SELECT PassedCourses.student AS student,SUM(PassedCourses.credits) AS research_credits
      FROM PassedCourses INNER JOIN Classified ON PassedCourses.course=Classified.course
      WHERE(Classified.classification='research') GROUP BY student),
  SeminarCredits AS
    (SELECT PassedCourses.student AS student,COUNT(PassedCourses.credits) AS seminar_count
      FROM PassedCourses INNER JOIN Classified ON PassedCourses.course=Classified.course
      WHERE(Classified.classification='seminar') GROUP BY student),
  RecommendedBranchCredits AS
    (SELECT StudentBranches.student, RecommendedBranch.course, Courses.credits AS recommendedBranchCredits FROM
      (StudentBranches JOIN RecommendedBranch USING(branch,program)) JOIN Courses ON course=code
      INTERSECT (SELECT * FROM PassedCourses)),
  allCredits AS
    (SELECT idnr AS student, COALESCE(total_credits,0) AS totalCredits, COALESCE(mandatory_count,0) AS mandatoryLeft,
    COALESCE(math_credits,0) AS mathCredits, COALESCE(research_credits,0) AS researchCredits, COALESCE(seminar_count,0) AS seminarCourses,
    COALESCE(recommendedBranchCredits,0) AS recommendedBranchCredits
    FROM Students LEFT JOIN (TotalCredits NATURAL FULL JOIN MandatoryLeft NATURAL FULL JOIN MathCredits NATURAL FULL JOIN
    ResearchCredits NATURAL FULL JOIN SeminarCredits NATURAL FULL JOIN RecommendedBranchCredits) on idnr=student)
SELECT DISTINCT student, totalCredits, mandatoryLeft, mathCredits, researchCredits, seminarCourses,
(mandatoryLeft=0 AND mathCredits>=20 AND researchCredits>=10 AND seminarCourses>=1 AND recommendedBranchCredits>=10) AS qualified
FROM allCredits ORDER BY student ASC;


-----------------------
-- Inserts --
-----------------------

--Inserts for new tables
INSERT INTO Departments VALUES ('Dep1', 'D1');
INSERT INTO Departments VALUES ('Dep2', 'D2');

INSERT INTO Programs VALUES ('Prog1','P1');
INSERT INTO Programs VALUES ('Prog2','P2');

INSERT INTO ProgramInDepartment VALUES ('Prog1', 'Dep1');
INSERT INTO ProgramInDepartment VALUES ('Prog2', 'Dep2');

--Original inserts
INSERT INTO Branches VALUES ('B1', 'Prog1');
INSERT INTO Branches VALUES ('B2', 'Prog1');
INSERT INTO Branches VALUES ('B1', 'Prog2');

INSERT INTO Students VALUES ('1111111111', 'N1', 'ls1', 'Prog1');
INSERT INTO Students VALUES ('2222222222', 'N2', 'ls2', 'Prog1');
INSERT INTO Students VALUES ('3333333333', 'N3', 'ls3', 'Prog2');
INSERT INTO Students VALUES ('4444444444', 'N4', 'ls4', 'Prog1');
INSERT INTO Students VALUES ('5555555555', 'Nx', 'ls5', 'Prog2');
INSERT INTO Students VALUES ('6666666666', 'Nx', 'ls6', 'Prog2');

INSERT INTO Courses VALUES ('CCC111', 'C1', 22.5, 'Dep1');
INSERT INTO Courses VALUES ('CCC222', 'C2', 20,   'Dep1');
INSERT INTO Courses VALUES ('CCC333', 'C3', 30,   'Dep1');
INSERT INTO Courses VALUES ('CCC444', 'C4', 40,   'Dep1');
INSERT INTO Courses VALUES ('CCC555', 'C5', 50,   'Dep1');

--Added inserts for prerequisites
INSERT INTO Prerequisites VALUES ('CCC444', 'CCC111');
INSERT INTO Prerequisites VALUES ('CCC444', 'CCC333');
--INSERT INTO Prerequisites VALUES ('CCC555', 'CCC222');

INSERT INTO LimitedCourses VALUES ('CCC222', 2);
INSERT INTO LimitedCourses VALUES ('CCC333', 2);

INSERT INTO Classifications VALUES ('math');
INSERT INTO Classifications VALUES ('research');
INSERT INTO Classifications VALUES ('seminar');

INSERT INTO Classified VALUES ('CCC333', 'math');
INSERT INTO Classified VALUES ('CCC444', 'research');
INSERT INTO Classified VALUES ('CCC444','seminar');

INSERT INTO StudentBranches VALUES ('2222222222', 'B1', 'Prog1');
INSERT INTO StudentBranches VALUES ('3333333333', 'B1', 'Prog2');
INSERT INTO StudentBranches VALUES ('4444444444', 'B1', 'Prog1');


INSERT INTO MandatoryProgram VALUES ('CCC111', 'Prog1');

INSERT INTO MandatoryBranch VALUES ('CCC333', 'B1', 'Prog1');
INSERT INTO MandatoryBranch VALUES ('CCC555', 'B1', 'Prog2');

INSERT INTO RecommendedBranch VALUES ('CCC222', 'B1', 'Prog1');
INSERT INTO RecommendedBranch VALUES ('CCC333', 'B2', 'Prog1');

INSERT INTO Registered VALUES ('1111111111', 'CCC111');
INSERT INTO Registered VALUES ('1111111111', 'CCC222');
INSERT INTO Registered VALUES ('2222222222', 'CCC222');
INSERT INTO Registered VALUES ('5555555555', 'CCC333');
INSERT INTO Registered VALUES ('1111111111', 'CCC333');

INSERT INTO WaitingList VALUES ('3333333333', 'CCC222', 1);
INSERT INTO WaitingList VALUES ('3333333333', 'CCC333', 1);
INSERT INTO WaitingList VALUES ('2222222222', 'CCC333', 2);

INSERT INTO Taken VALUES('2222222222', 'CCC111', 'U');
INSERT INTO Taken VALUES('2222222222', 'CCC222', 'U');
INSERT INTO Taken VALUES('2222222222', 'CCC444', 'U');

INSERT INTO Taken VALUES('4444444444', 'CCC111', '5');
INSERT INTO Taken VALUES('4444444444', 'CCC222', '5');
INSERT INTO Taken VALUES('4444444444', 'CCC333', '5');
INSERT INTO Taken VALUES('4444444444', 'CCC444', '5');

INSERT INTO Taken VALUES('5555555555', 'CCC111', '5');
INSERT INTO Taken VALUES('5555555555', 'CCC333', '5');
INSERT INTO Taken VALUES('5555555555', 'CCC444', '5');

--Additional inserts for tests
INSERT INTO LimitedCourses VALUES ('CCC111', 3);
INSERT INTO Registered VALUES ('5555555555', 'CCC555');

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

------------------------------