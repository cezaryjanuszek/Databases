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
    BEGIN
        studentStatus := (SELECT status FROM Registrations WHERE student=OLD.student AND course=OLD.course);
        IF (NOT EXISTS (SELECT student, course FROM Registrations WHERE student=OLD.student AND course=OLD.course)) THEN
            RAISE EXCEPTION 'ERROR: this student is not in the registrations for this course!';

        ELSEIF (studentStatus = 'registered') THEN
            DELETE FROM Registered WHERE student=OLD.student AND course=OLD.course;
        ELSEIF (studentStatus = 'waiting') THEN
            DELETE FROM WaitingList WHERE student=OLD.student AND course=OLD.course;
        END IF;
        RETURN OLD;
    END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS deleteRegistration ON Registrations;

CREATE TRIGGER deleteRegistration
    INSTEAD OF DELETE ON Registrations
    FOR EACH ROW
    EXECUTE FUNCTION unregisterStudent ();

