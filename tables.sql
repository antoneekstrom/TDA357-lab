DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE TABLE Students (
  idnr VARCHAR(16) PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  login VARCHAR(64) NOT NULL,
  program VARCHAR(64) NOT NULL 
);

CREATE TABLE Branches (
  name VARCHAR(64) NOT NULL,
  program VARCHAR(64) NOT NULL,
  PRIMARY KEY (name, program)
);

CREATE TABLE Courses (
  code CHAR(6) NOT NULL PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  credits FLOAT NOT NULL,
  department VARCHAR(64) NOT NULL
);

CREATE TABLE LimitedCourses (
  code CHAR(6) NOT NULL PRIMARY KEY REFERENCES Courses,
  capacity INT NOT NULL CHECK (capacity > 0)
);

CREATE TABLE StudentBranches (
  student VARCHAR(16) REFERENCES Students,
  branch VARCHAR(64) NOT NULL,
  program VARCHAR(64) NOT NULL,
  FOREIGN KEY (branch, program) REFERENCES Branches
);

CREATE TABLE Classifications (
  name VARCHAR(64) NOT NULL PRIMARY KEY
);

CREATE TABLE Classified (
  course CHAR(6) NOT NULL REFERENCES Courses,
  classification VARCHAR(64) NOT NULL REFERENCES Classifications
);

CREATE TABLE MandatoryProgram (
  course CHAR(6) NOT NULL REFERENCES Courses,
  program VARCHAR(64) NOT NULL PRIMARY KEY
);

CREATE TABLE MandatoryBranch (
  course CHAR(6) NOT NULL REFERENCES Courses,
  branch VARCHAR(64) NOT NULL,
  program VARCHAR(64) NOT NULL,
  FOREIGN KEY (branch, program) REFERENCES Branches
);

CREATE TABLE RecommendedBranch (
  course CHAR(6) NOT NULL REFERENCES Courses,
  branch VARCHAR(64) NOT NULL,
  program VARCHAR(64) NOT NULL,
  FOREIGN KEY (branch, program) REFERENCES Branches
);

CREATE TABLE Registered (
  student VARCHAR(16) REFERENCES Students,
  course CHAR(6) NOT NULL REFERENCES Courses
);

CREATE TABLE Taken (
  student VARCHAR(16) REFERENCES Students,
  course CHAR(6) NOT NULL REFERENCES Courses,
  grade CHAR(1) CHECK (grade IN ('U', '3', '4', '5'))
);

CREATE TABLE WaitingList (
  student VARCHAR(16) REFERENCES Students,
  course CHAR(6) NOT NULL REFERENCES Limitedcourses,
  position TIMESTAMP
);