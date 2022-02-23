-- TEST #1: Register for an unlimited course.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('2222222222', 'CCC444');

-- TEST #2: Register an already registered student.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('2222222222', 'CCC444');

-- TEST #3: Unregister from an unlimited course.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations where student = '2222222222' AND course = 'CCC444';

-- TEST #4: Register to limited course.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('4444444444', 'CCC555');

-- TEST #5: Try to register for course already passed.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('4444444444', 'CCC222');

-- TEST #6: Unregister from a limited course without waiting list.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations where student = '4444444444' AND course = 'CCC555';

-- TEST #7: Unregister from a limited course with waiting list while being in the middle of the waiting list.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations where student = '2222222222' AND course = 'CCC333';

-- TEST #8: Unregister from a limited course with waiting list while being registered.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations where student = '1111111111' AND course = 'CCC333';

-- TEST #9: Unregister from an overfull course with waiting list while being registered.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations where student = '1111111111' AND course = 'CCC222';

-- TEST #10: Wait for limited course.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('7777777777', 'CCC222');