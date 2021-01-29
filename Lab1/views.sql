
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
