 "required": [
    "student",
    "name",
    "login",
    "program",
    "branch",
    "finished",
    "registered",
    "seminarCourses",
    "mathCredits",
    "researchCredits",
    "totalCredits",
    "canGraduate"
  ],
  (SELECT
  json_build_object('seminarCourses',seminarcourses,'mathCredits',mathcredits,'researchCredits',
  researchcredits,'totalCredits',totalCredits,'canGraduate',qualified) from pathtograduation where student='4444444444');
select json_build_object('student',idnr,'name',name,'login',login,'program',program,'branch',branch from basicinformation where student='4444444444')
"required": [
          "course",
          "code",
          "credits",
          "grade"
        ],
select finishedcourses.student,
json_agg(json_build_object('course',courses.name,'code',finishedcourses.course,'credits',finishedcourses.credits,'grade',finishedcourses.grade))
from finishedcourses JOIN courses on(finishedcourses.course=courses.code) WHERE finishedcourses.student='4444444444';

SELECT json_build_object ('student', idnr, 'name', name, 'login', login, 'program', program, 'branch', branch,
'finished', (SELECT COALESCE (json_agg(json_build_object('course', name, 'code', course, 'credits', Courses.credits, 'grade', grade)), '[]')
                FROM FinishedCourses JOIN Courses ON (course=code) WHERE student=?),
'registered', (SELECT COALESCE (json_agg(json_build_object('course', name, 'code', course, 'status', status)), '[]')
                FROM Registrations JOIN Courses ON (course=code) WHERE student=?), 'seminarCourses', seminarCourses,
'mathCredits', mathCredits, 'researchCredits', researchCredits, 'totalCredits', totalCredits, 'canGraduate', qualified ) AS jsondata
FROM BasicInformation JOIN PathToGraduation ON (idnr=student) WHERE idnr=?;