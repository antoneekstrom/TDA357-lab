
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
  SELECT student, recommendedbranch.course, passedcourses.credits
  FROM passedcourses
  LEFT JOIN basicinformation ON passedcourses.student=basicinformation.idnr
  LEFT JOIN recommendedbranch ON recommendedbranch.program=basicinformation.program AND recommendedbranch.branch=basicinformation.branch;
);

CREATE OR REPLACE VIEW PathToGraduation AS (
  SELECT
    idnr as student,
    COALESCE(totalCredits.total, 0) AS totalCredits,
    COALESCE(mandatoryLeft.total, 0) AS mandatoryLeft,
    COALESCE(mathCredits.total, 0) AS mathCredits,
    COALESCE(researchCredits.total, 0) AS researchCredits,
    COALESCE(seminarCourses.total, 0) AS seminarCourses,
    student.branch != NULL AND mandatoryLeft == 0 AND 
    AS 'qualified'
  FROM basicinformation
  LEFT JOIN totalCredits ON idnr=totalCredits.student
  LEFT JOIN mandatoryLeft ON idnr=mandatoryLeft.student
  LEFT JOIN mathCredits ON idnr=mathCredits.student
  LEFT JOIN researchCredits ON idnr=researchCredits.student
  LEFT JOIN seminarCourses ON idnr=seminarCourses.student
);