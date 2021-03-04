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
--view courseQueuePositions (what difference with WaitingList?)
CREATE OR REPLACE VIEW  courseQueuePositions AS
    SELECT course, student, position AS place FROM WaitingList;

--REGISTRATION TRIGGER
CREATE OR REPLACE FUNCTION registerStudent () RETURNS TRIGGER AS $$
    DECLARE
    nbOfStudentsInCourse INT;
    limitedCapacity INT;
    maxPos INT;
    BEGIN
        nbOfStudentsInCourse := (SELECT COUNT(student)  FROM Registered WHERE course=NEW.course);
        maxPos := (SELECT MAX(position) FROM WaitingList WHERE course=NEW.course);

        IF (EXISTS (SELECT student, course FROM Registrations WHERE student=NEW.student AND course=NEW.course) ) THEN
            RAISE EXCEPTION 'ERROR: this student is already in the registrations for this course!';

        ELSEIF (EXISTS (SELECT student, course FROM PassedCourses WHERE student=NEW.student AND course=NEW.course) ) THEN
                    RAISE EXCEPTION 'ERROR: this student has already passed this course!';

        ELSEIF ( EXISTS (WITH a AS (SELECT (prereq_code) FROM Prerequisites WHERE(code=NEW.course)),
                     b AS (select (course) FROM PassedCourses WHERE(student=NEW.student AND (course IN(SELECT prereq_code FROM a))))
                     SELECT (prereq_code) FROM a WHERE (prereq_code NOT IN(SELECT course FROM b)))) THEN
            RAISE EXCEPTION 'ERROR: this student did not meet all the prerequisites for this course!';

        ELSEIF (EXISTS (SELECT code FROM LimitedCourses WHERE code=NEW.course) ) THEN
            limitedCapacity := (SELECT capacity FROM LimitedCourses WHERE code=NEW.course);
            IF (nbOfStudentsInCourse >= limitedCapacity) THEN
                IF (EXISTS (SELECT course FROM WaitingList WHERE course=NEW.course)) THEN
                    INSERT INTO WaitingList VALUES (NEW.student, NEW.course, maxPos+1);
                ELSE
                    INSERT INTO WaitingList VALUES (NEW.student, NEW.course, 1);
                END IF;
            ELSE
                    INSERT INTO Registered VALUES (NEW.student, NEW.course);
            END IF;
        ELSE
            INSERT INTO Registered VALUES (NEW.student, NEW.course);
        END IF;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS addRegistration ON Registrations;

CREATE TRIGGER addRegistration
    INSTEAD OF INSERT ON Registrations
    FOR EACH ROW
    EXECUTE FUNCTION registerStudent ();

--UNREGISTRATION TRIGGER
CREATE OR REPLACE FUNCTION unregisterStudent () RETURNS TRIGGER AS $$
    DECLARE
        studentStatus TEXT;
        studentToInsert CHAR(10);
        LastPosition INT;
        currentPosition INT;
        limitedCapacity INT;
        studentCount INT;
    BEGIN
        studentStatus := (SELECT status FROM Registrations WHERE student=OLD.student AND course=OLD.course);

        IF (NOT EXISTS (SELECT code FROM LimitedCourses WHERE code=OLD.course) ) THEN --unregister from unlimited course
            DELETE FROM Registered WHERE student=OLD.student AND course=OLD.course;

        ELSEIF (studentStatus = 'registered') THEN
            limitedCapacity := (SELECT capacity FROM LimitedCourses WHERE code=OLD.course);

            DELETE FROM Registered WHERE student=OLD.student AND course=OLD.course;
            studentCount := (SELECT COUNT(student) FROM Registered WHERE course=OLD.course); --count to check if not overfull

            IF (EXISTS (SELECT course FROM courseQueuePositions WHERE course=OLD.course) AND (studentCount<limitedCapacity)) THEN --limited with waiting list
                studentToInsert := (SELECT student FROM courseQueuePositions WHERE course=OLD.course AND place=1);
                INSERT INTO Registered VALUES (studentToInsert,OLD.course);
                --remove the student from waitinglist and update it
                LastPosition:=(SELECT MAX(place) FROM courseQueuePositions WHERE(course=OLD.course));
                DELETE FROM WaitingList WHERE student=studentToInsert AND course=OLD.course;
                IF(1!=LastPosition) THEN
                    FOR counter IN 2..LastPosition loop
                        UPDATE WaitingList SET position = counter-1 WHERE(course=OLD.course AND position=counter);
                    END loop;
                END IF;
            END IF;

        ELSEIF (studentStatus = 'waiting') THEN --remove from waiting list
            currentPosition:=(SELECT place FROM courseQueuePositions WHERE(student=OLD.student AND course=OLD.course));
            LastPosition:=(SELECT MAX(place) FROM courseQueuePositions WHERE(course=OLD.course));
            DELETE FROM WaitingList WHERE student=OLD.student AND course=OLD.course;
            IF(currentPosition!=LastPosition) THEN
                FOR counter IN currentPosition+1..LastPosition loop
                    UPDATE WaitingList SET position = counter-1 WHERE(course=OLD.course AND position=counter);
                END loop;
            END IF;
        END IF;

        RETURN OLD;
    END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS deleteRegistration ON Registrations;

CREATE TRIGGER deleteRegistration
    INSTEAD OF DELETE ON Registrations
    FOR EACH ROW
    EXECUTE FUNCTION unregisterStudent ();

