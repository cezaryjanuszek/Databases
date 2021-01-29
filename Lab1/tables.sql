--students table
CREATE TABLE Students(
  idnr CHAR(10) PRIMARY KEY, 
  name TEXT NOT NULL, 
  login CHAR(10) NOT NULL,
  program TEXT NOT NULL);

--branches table
CREATE TABLE Branches (
name TEXT,
program TEXT,
PRIMARY KEY (name,program) );

--Courses table
CREATE TABLE Courses (
code CHAR(6) PRIMARY KEY,
name TEXT NOT NULL,
credits FLOAT NOT NULL,
department TEXT NOT NULL);

--LimitedCourses(code, capacity)
CREATE TABLE LimitedCourses(code CHAR(6) PRIMARY KEY,
capacity INT NOT NULL,
CONSTRAINT capacity_ok CHECK (capacity >= 0),
FOREIGN KEY(code) REFERENCES Courses(code));

--Student branches table
CREATE TABLE StudentBranches (
student CHAR(10) PRIMARY KEY,
branch TEXT NOT NULL,
program TEXT NOT NULL,
FOREIGN KEY (student) REFERENCES Students(idnr),
FOREIGN KEY (branch, program) REFERENCES Branches );

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
program TEXT,PRIMARY KEY(course,program),
FOREIGN KEY(course) REFERENCES Courses(code));


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
position SERIAL NOT NULL,
PRIMARY KEY (student, course),
FOREIGN KEY (student) REFERENCES Students(idnr),
FOREIGN KEY (course) REFERENCES LimitedCourses(code) );

