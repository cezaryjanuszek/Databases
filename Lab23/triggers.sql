--view courseQueuePositions (what difference with WaitingList?)
CREATE VIEW  courseQueuePositions AS
    SELECT course, student, position AS place FROM WaitingList;

--trigger for registering students
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

CREATE TRIGGER addRegistration 
    INSTEAD OF INSERT ON Registrations
    FOR EACH ROW 
    EXECUTE FUNCTION registerStudent ();

--BRUDNOPIS: prerequisites for registration
--SELECT prereq_code FROM Prerequisites WHERE code=NEW.course

--SELECT course FROM PassedCourses WHERE student=NEW.student;

--with a as (select (prereq_code) from Prerequisites WHERE(code=NEW.course)),
--b as (select (course) from PassedCourses WHERE(student=NEW.student AND (course IN(select prereq_code from a))))
--select (prereq_code) from a WHERE (prereq_code NOT IN(select course from b));
--SELECT COUNT(student) AS nbOfStudents FROM Registered WHERE course=NEW.course