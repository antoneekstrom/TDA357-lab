DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE TABLE Departments (
  name VARCHAR(64) PRIMARY KEY,
  abbr VARCHAR(64) UNIQUE NOT NULL
);

CREATE TABLE Programs (
  name VARCHAR(64) PRIMARY KEY,
  abbr VARCHAR(64) NOT NULL
);

CREATE TABLE Students (
  idnr CHAR(10) PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  login VARCHAR(64) UNIQUE NOT NULL,
  program VARCHAR(64) NOT NULL REFERENCES Programs,
  UNIQUE(idnr, program)
);

CREATE TABLE Branches (
  name VARCHAR(64) NOT NULL,
  program VARCHAR(64) NOT NULL,
  PRIMARY KEY (name, program)
);

CREATE TABLE Courses (
  code CHAR(6) PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  credits FLOAT NOT NULL CHECK (credits > 0)
);

CREATE TABLE PrerequisiteCourses (
  course CHAR(6) REFERENCES Courses,
  prerequisite CHAR(6) REFERENCES Courses,
  PRIMARY KEY (course, prerequisite)
);

CREATE TABLE LimitedCourses (
  code CHAR(6) PRIMARY KEY REFERENCES Courses,
  capacity INT NOT NULL CHECK (capacity > 0)
);

CREATE TABLE Classifications (
  name VARCHAR(64) PRIMARY KEY
);

CREATE TABLE Classified (
  course CHAR(6) NOT NULL REFERENCES Courses,
  classification VARCHAR(64) NOT NULL REFERENCES Classifications,
  PRIMARY KEY (course, classification)
);

CREATE TABLE DepInProgram (
  department VARCHAR(64) NOT NULL REFERENCES Departments,
  program VARCHAR(64) NOT NULL REFERENCES Programs,
  PRIMARY KEY (department, program)
);

CREATE TABLE GivenBy (
  department VARCHAR(64) NOT NULL REFERENCES Departments,
  course CHAR(6) PRIMARY KEY REFERENCES Courses
);

CREATE TABLE MandatoryBranch (
  course CHAR(6) NOT NULL REFERENCES Courses,
  branch VARCHAR(64) NOT NULL,
  program VARCHAR(64) NOT NULL,
  FOREIGN KEY (branch, program) REFERENCES Branches,
  PRIMARY KEY (course, branch, program)
);

CREATE TABLE RecommendedBranch (
  course CHAR(6) NOT NULL REFERENCES Courses,
  branch VARCHAR(64) NOT NULL,
  program VARCHAR(64) NOT NULL,
  FOREIGN KEY (branch, program) REFERENCES Branches,
  PRIMARY KEY (course, branch, program)
);

CREATE TABLE StudentBranches (
  student VARCHAR(16) PRIMARY KEY REFERENCES Students,
  branch VARCHAR(64) NOT NULL,
  program VARCHAR(64) NOT NULL,
  FOREIGN KEY (branch, program) REFERENCES Branches(name, program),
  FOREIGN KEY (student, program) REFERENCES Students(idnr, program)
);

CREATE TABLE MandatoryProgram (
  course CHAR(6) NOT NULL REFERENCES Courses,
  program VARCHAR(64) NOT NULL,
  PRIMARY KEY (course, program)
);

CREATE TABLE Registered (
  student VARCHAR(16) REFERENCES Students,
  course CHAR(6) NOT NULL REFERENCES Courses,
  PRIMARY KEY (student, course)
);

CREATE TABLE Taken (
  student VARCHAR(16) REFERENCES Students,
  course CHAR(6) NOT NULL REFERENCES Courses,
  grade CHAR(1) NOT NULL CHECK (grade IN ('U', '3', '4', '5')),
  PRIMARY KEY (student, course)
);

CREATE TABLE WaitingList (
  student VARCHAR(16) REFERENCES Students,
  course CHAR(6) NOT NULL REFERENCES Limitedcourses,
  position TIMESTAMP NOT NULL DEFAULT(NOW()),
  PRIMARY KEY (student, course),
  UNIQUE(course, position)
);

CREATE OR REPLACE VIEW BasicInformation AS (
  SELECT idnr, name, login, students.program, branch
  FROM students
  LEFT JOIN studentbranches ON idnr=student
);

CREATE OR REPLACE VIEW FinishedCourses AS (
  SELECT student, course, grade, credits
  FROM students
  JOIN taken ON idnr=student
  JOIN courses ON code=course
);

CREATE OR REPLACE VIEW PassedCourses AS (
  SELECT student, course, credits
  FROM FinishedCourses
  WHERE grade != 'U'
);

CREATE OR REPLACE VIEW Registrations AS (
  SELECT student, course, 'registered' AS status
  FROM registered
  UNION
  SELECT student, course, 'waiting' AS status
  FROM waitinglist
);

CREATE OR REPLACE VIEW MandatoryCourses AS (
  SELECT idnr, basicinformation.program, basicinformation.branch, course
  FROM basicinformation
  JOIN mandatoryprogram ON mandatoryprogram.program=basicinformation.program
  UNION
  SELECT idnr, basicinformation.program, basicinformation.branch, course
  FROM basicinformation
  JOIN mandatorybranch ON mandatorybranch.program=basicinformation.program AND mandatorybranch.branch=basicinformation.branch
);

CREATE OR REPLACE VIEW UnreadMandatory AS (
  SELECT students.idnr AS student, mandatorycourses.course
  FROM students
  JOIN mandatorycourses ON students.idnr=mandatorycourses.idnr
  EXCEPT
  SELECT student, course
  FROM passedcourses
);

CREATE OR REPLACE VIEW TotalCredits AS (
  SELECT student, SUM(credits) AS total
  FROM passedcourses
  GROUP BY student
);

CREATE OR REPLACE VIEW MandatoryLeft AS (
  SELECT student, COUNT(student) AS total
  FROM unreadmandatory
  GROUP BY student
);

CREATE OR REPLACE VIEW MathCredits AS (
  SELECT student, SUM(credits) AS total
  FROM passedcourses
  JOIN classified ON passedcourses.course=classified.course
  WHERE classification='math'
  GROUP BY student, classification
);

CREATE OR REPLACE VIEW ResearchCredits AS (
  SELECT student, SUM(credits) AS total
  FROM passedcourses
  JOIN classified ON passedcourses.course=classified.course
  WHERE classification='research'
  GROUP BY student, classification
);

CREATE OR REPLACE VIEW SeminarCourses AS (
  SELECT student, COUNT(student) AS total
  FROM passedcourses
  JOIN classified ON passedcourses.course=classified.course
  WHERE classification='seminar'
  GROUP BY student, classification
);

CREATE OR REPLACE VIEW RecommendedCourses AS (
  SELECT student, passedcourses.course, passedcourses.credits
  FROM passedcourses
  LEFT JOIN basicinformation ON passedcourses.student=basicinformation.idnr
  JOIN recommendedbranch
  ON recommendedbranch.program=basicinformation.program
  AND recommendedbranch.branch=basicinformation.branch
  AND recommendedbranch.course=passedcourses.course
);

CREATE OR REPLACE VIEW RecommendedCredits AS (
  SELECT student, SUM(credits) AS total
  FROM recommendedcourses
  GROUP BY student
);

CREATE OR REPLACE VIEW PathToGraduation AS (
  SELECT
    idnr as student,
    COALESCE(totalCredits.total, 0) AS totalCredits,
    COALESCE(mandatoryLeft.total, 0) AS mandatoryLeft,
    COALESCE(mathCredits.total, 0) AS mathCredits,
    COALESCE(researchCredits.total, 0) AS researchCredits,
    COALESCE(seminarCourses.total, 0) AS seminarCourses,
    basicinformation.branch IS NOT NULL
    AND COALESCE(mandatoryLeft.total, 0) = 0
    AND COALESCE(recommendedCredits.total, 0) >= 10
    AND COALESCE(mathCredits.total, 0) >= 20
    AND COALESCE(researchCredits.total, 0) >= 10
    AND COALESCE(seminarCourses.total, 0) > 0
    AS qualified
  FROM basicinformation
  LEFT JOIN totalCredits ON idnr=totalCredits.student
  LEFT JOIN mandatoryLeft ON idnr=mandatoryLeft.student
  LEFT JOIN mathCredits ON idnr=mathCredits.student
  LEFT JOIN researchCredits ON idnr=researchCredits.student
  LEFT JOIN seminarCourses ON idnr=seminarCourses.student
  LEFT JOIN recommendedCredits ON idnr=recommendedCredits.student
);

INSERT INTO Branches VALUES ('B1','Prog1');
INSERT INTO Branches VALUES ('B2','Prog1');
INSERT INTO Branches VALUES ('B1','Prog2');

INSERT INTO Programs VALUES ('Prog1','P1');
INSERT INTO Programs VALUES ('Prog2','P2');

INSERT INTO Departments VALUES ('Dep1','D1');

INSERT INTO Students VALUES ('1111111111','N1','ls1','Prog1');
INSERT INTO Students VALUES ('2222222222','N2','ls2','Prog1');
INSERT INTO Students VALUES ('3333333333','N3','ls3','Prog2');
INSERT INTO Students VALUES ('4444444444','N4','ls4','Prog1');
INSERT INTO Students VALUES ('5555555555','Nx','ls5','Prog2');
INSERT INTO Students VALUES ('6666666666','Nx','ls6','Prog2');
INSERT INTO Students VALUES ('7777777777','Nx','ls7','Prog2');

INSERT INTO Courses VALUES ('CCC111','C1',22.5);
INSERT INTO Courses VALUES ('CCC222','C2',20);
INSERT INTO Courses VALUES ('CCC333','C3',30);
INSERT INTO Courses VALUES ('CCC444','C4',60);
INSERT INTO Courses VALUES ('CCC555','C5',50);

INSERT INTO PrerequisiteCourses VALUES ('CCC111','CCC222');
INSERT INTO PrerequisiteCourses VALUES ('CCC111','CCC333');

INSERT INTO GivenBy VALUES ('Dep1','CCC111');
INSERT INTO GivenBy VALUES ('Dep1','CCC222');
INSERT INTO GivenBy VALUES ('Dep1','CCC333');
INSERT INTO GivenBy VALUES ('Dep1','CCC444');
INSERT INTO GivenBy VALUES ('Dep1','CCC555');

INSERT INTO LimitedCourses VALUES ('CCC222',1);
INSERT INTO LimitedCourses VALUES ('CCC333',2);
INSERT INTO LimitedCourses VALUES ('CCC555',1);

INSERT INTO Classifications VALUES ('math');
INSERT INTO Classifications VALUES ('research');
INSERT INTO Classifications VALUES ('seminar');

INSERT INTO Classified VALUES ('CCC333','math');
INSERT INTO Classified VALUES ('CCC444','math');
INSERT INTO Classified VALUES ('CCC444','research');
INSERT INTO Classified VALUES ('CCC444','seminar');


INSERT INTO StudentBranches VALUES ('2222222222','B1','Prog1');
INSERT INTO StudentBranches VALUES ('3333333333','B1','Prog2');
INSERT INTO StudentBranches VALUES ('4444444444','B1','Prog1');
INSERT INTO StudentBranches VALUES ('5555555555','B1','Prog2');

INSERT INTO MandatoryProgram VALUES ('CCC111','Prog1');

INSERT INTO MandatoryBranch VALUES ('CCC333', 'B1', 'Prog1');
INSERT INTO MandatoryBranch VALUES ('CCC444', 'B1', 'Prog2');

INSERT INTO RecommendedBranch VALUES ('CCC222', 'B1', 'Prog1');
INSERT INTO RecommendedBranch VALUES ('CCC333', 'B1', 'Prog2');

INSERT INTO Registered VALUES ('1111111111','CCC111');
INSERT INTO Registered VALUES ('1111111111','CCC222');
INSERT INTO Registered VALUES ('1111111111','CCC333');
INSERT INTO Registered VALUES ('2222222222','CCC222');
INSERT INTO Registered VALUES ('5555555555','CCC222');
INSERT INTO Registered VALUES ('5555555555','CCC333');

INSERT INTO Taken VALUES('4444444444','CCC111','5');
INSERT INTO Taken VALUES('4444444444','CCC222','5');
INSERT INTO Taken VALUES('4444444444','CCC333','5');
INSERT INTO Taken VALUES('4444444444','CCC444','5');

INSERT INTO Taken VALUES('5555555555','CCC111','5');
INSERT INTO Taken VALUES('5555555555','CCC222','4');
INSERT INTO Taken VALUES('5555555555','CCC444','3');

INSERT INTO Taken VALUES('2222222222','CCC111','U');
INSERT INTO Taken VALUES('2222222222','CCC222','U');
INSERT INTO Taken VALUES('2222222222','CCC444','U');

INSERT INTO WaitingList VALUES('3333333333','CCC222', NOW());
INSERT INTO WaitingList VALUES('3333333333','CCC333', NOW() + INTERVAL '1 seconds');
INSERT INTO WaitingList VALUES('2222222222','CCC333', NOW() + INTERVAL '2 seconds');
INSERT INTO WaitingList VALUES('5555555555','CCC333', NOW() + INTERVAL '3 seconds');
