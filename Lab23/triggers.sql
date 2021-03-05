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

