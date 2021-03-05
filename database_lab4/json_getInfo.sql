SELECT json_build_object ('student', idnr, 'name', name, 'login', login, 'program', program, 'branch', branch,
'finished', (SELECT COALESCE (json_agg(json_build_object('course', name, 'code', course, 'credits', Courses.credits, 'grade', grade)), '[]')
                FROM FinishedCourses JOIN Courses ON (course=code) WHERE student='4444444444'),
'registered', (SELECT COALESCE (json_agg(json_build_object('course', name, 'code', course, 'status', status)), '[]')
                FROM Registrations JOIN Courses ON (course=code) WHERE student='4444444444'), 'seminarCourses', seminarCourses,
'mathCredits', mathCredits, 'researchCredits', researchCredits, 'totalCredits', totalCredits, 'canGraduate', qualified ) AS jsondata
FROM BasicInformation JOIN PathToGraduation ON (idnr=student) WHERE idnr='4444444444';