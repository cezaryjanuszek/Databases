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

