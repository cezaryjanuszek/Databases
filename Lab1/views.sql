--Views
--BasicInformation(idnr, name, login, program, branch): for all students, their national identification number, name,
  --  login, their program and the branch (if any). The branch column is the only column in any of the views that is
  --allowed to contain NULL.
--FinishedCourses(student, course, grade, credits): for all students, all finished courses, along with their codes, grades
  --  ('U', '3', '4' or '5') and number of credits. The type of the grade should be a character type, e.g. CHAR(1).
--PassedCourses(student, course, credits): for all students, all passed courses, i.e. courses finished with a grade other
    --than 'U', and the number of credits for those courses. This view is intended as a helper view towards later views
     --(and for part 4), and will not be directly used by your application.
--Registrations(student, course, status): all registered and waiting students for all courses, along with their waiting
    --status ('registered' or 'waiting').
--UnreadMandatory(student, course): for all students, the mandatory courses (branch and program) they have not passed
    --yet. This view is intended as a helper view towards the PathToGraduation view, and will not be directly used by
    --your application.
--PathToGraduation(student, totalCredits, mandatoryLeft, mathCredits, researchCredits, seminarCourses, qualified):
    --for all students, their path to graduation, i.e. a view with columns for:
--student: the student's national identification number;
--totalCredits: the number of credits they have taken;
--mandatoryLeft: the number of courses that are mandatory for a branch or a program they have yet to read;
--mathCredits: the number of credits they have taken in courses that are classified as math courses;
--researchCredits: the number of credits they have taken in courses that are classified as research courses;
--seminarCourses: the number of seminar courses they have passed;
--qualified: whether or not they qualify for graduation. The SQL type of this field should be BOOLEAN (i.e. TRUE or FALSE).
--Hint1: For the last view, make a query for the data of each column and when they all work, put them in a WITH clause
    --and use a chain of (left) outer joins to combine them.

--Hint2: Use COALESCE to replace null values with 0 (e.g. COALESCE(totalCredits,0) AS totalCredits). Also, keep in mind
    --that comparing null values with anything gives UNKNOWN!

--Hint3: A query containing student/classification/credit with a row for each classification of each course every
    --student has passed may be useful.

--Make sure that your views use the right names of columns! Use AS to name a column.

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
CREATE VIEW StudentMandatory AS SELECT Students.idnr,MandatoryProgram.Course FROM Students JOIN MandatoryProgram ON Students.Program=MandatoryProgram.program UNION
SELECT StudentBranches.student,MandatoryBranch.course
FROM StudentBranches JOIN MandatoryBranch ON StudentBranches.program=MandatoryBranch.program;

CREATE VIEW UnreadMandatory(student,course) AS SELECT idnr,course FROM StudentMandatory a WHERE NOT EXISTS (SELECT 1 FROM PassedCourses b WHERE a.idnr=b.student);

--View path to graduation

SELECT student, SUM(credits) AS totalcredits FROM PassedCourses GROUP BY student; --totalcredits
SELECT student, COUNT(*) AS mandatoryLeft FROM UnreadMandatory GROUP BY student;--mandatoryLeft

--MathCredits
SELECT PassedCourses.student,SUM(PassedCourses.credits) AS mathCredits
 FROM PassedCourses INNER JOIN Classified ON PassedCourses.course=Classified.course WHERE(Classified.classification='math') GROUP BY student;

--ResearchCredits
SELECT PassedCourses.student,SUM(PassedCourses.credits) AS researchCredits
 FROM PassedCourses INNER JOIN Classified ON PassedCourses.course=Classified.course WHERE(Classified.classification='research') GROUP BY student;

--SeminarCredits
SELECT PassedCourses.student,COUNT(PassedCourses.credits) AS seminarCourses
  FROM PassedCourses INNER JOIN Classified ON PassedCourses.course=Classified.course WHERE(Classified.classification='seminar') GROUP BY student;

--qualified
