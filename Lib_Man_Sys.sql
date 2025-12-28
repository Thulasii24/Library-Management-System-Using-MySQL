create database Lib_Man_Sys;
use Lib_Man_Sys;

-- Branch Table
create table branch(
	branch_id varchar(15) primary key,
	manager_id varchar(15),
	branch_address varchar(50),
	contact_no varchar(15)
);

-- Employees Table
CREATE TABLE employees(
	emp_id VARCHAR(10) PRIMARY KEY,
	emp_name VARCHAR(30),
	position VARCHAR(30),
	salary DECIMAL(10,2),
	branch_id VARCHAR(10),
	FOREIGN KEY (branch_id) REFERENCES  branch(branch_id)
);

-- Books Table
create table books(
	isbn VARCHAR(50) PRIMARY KEY,
	book_title VARCHAR(80),
	category VARCHAR(30),
	rental_price DECIMAL(10,2),
	status VARCHAR(10),
	author VARCHAR(30),
	publisher VARCHAR(30)
);

-- Members Table
CREATE TABLE members(
	member_id VARCHAR(10) PRIMARY KEY,
	member_name VARCHAR(30),
	member_address VARCHAR(30),
	reg_date DATE
);

-- Issue Status Table
CREATE TABLE issued_status(
	issued_id VARCHAR(10) PRIMARY KEY,
	issued_member_id VARCHAR(30),
	issued_book_name VARCHAR(80),
	issued_date DATE,
	issued_book_isbn VARCHAR(50),
	issued_emp_id VARCHAR(10),
	FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
	FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
	FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn) 
);

-- Return Status Table
CREATE TABLE return_status(
	return_id VARCHAR(10) PRIMARY KEY,
	issued_id VARCHAR(30),
	return_book_name VARCHAR(80),
	return_date DATE,
	return_book_isbn VARCHAR(50),
	FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);


select * from books;
select * from branch;
select * from employees;
select * from members;
select * from issued_status;
select * from return_status;

-- 1: Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';

-- 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE   issued_id =   'IS121';

-- 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT 
    issued_id,
    issued_book_isbn,
    issued_date
FROM issued_status
WHERE issued_emp_id = 'E101';


-- 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT
    issued_emp_id,
    COUNT(*) AS total_books
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(*) > 1;


-- > Create Table As Select (CTAS)
-- Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_issued_cnt AS
SELECT 
	b.isbn, 
    b.book_title, 
    COUNT(ist.issued_id) AS issue_count
FROM issued_status as ist
JOIN books as b
ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;


-- > Data Analysis & Findings
-- 1: Retrieve All Books in a Specific Category:
SELECT * FROM books
WHERE category = 'Classic';

-- 2: Find Total Rental Income by Category:
SELECT 
    b.category,
    SUM(b.rental_price),
    COUNT(*)
FROM issued_status as ist
JOIN books as b
ON b.isbn = ist.issued_book_isbn
GROUP BY 1;

-- 3: List Members Who Registered in the Last 180 Days:
SELECT *
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL 180 DAY;

-- 4: List Employees with Their Branch Manager's Name and their branch details:
SELECT 
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name as manager
FROM employees as e1
JOIN branch as b
ON e1.branch_id = b.branch_id    
JOIN employees as e2
ON e2.emp_id = b.manager_id;

-- 5: Create a Table of Books with Rental Price Above a Certain Threshold:
CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;

-- 6: Retrieve the List of Books Not Yet Returned
SELECT 
    ist.issued_id,
    bk.book_title,
    m.member_name
FROM issued_status ist
LEFT JOIN return_status rs
    ON rs.issued_id = ist.issued_id
JOIN books bk
    ON bk.isbn = ist.issued_book_isbn
JOIN members m
    ON m.member_id = ist.issued_member_id
WHERE rs.return_id IS NULL;


-- Advanced SQL Operation
-- Identifying  Members with Overdue Books
-- Query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m ON m.member_id = ist.issued_member_id
JOIN books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status as rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL AND
    (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1;


-- Update Book Status on Return
-- query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

DELIMITER $$

CREATE PROCEDURE add_return_records (
    IN p_return_id VARCHAR(10),
    IN p_issued_id VARCHAR(30)
)
BEGIN
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

    SELECT 
        issued_book_isbn,
        issued_book_name
    INTO 
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    INSERT INTO return_status (
        return_id,
        issued_id,
        return_book_name,
        return_date,
        return_book_isbn
    )
    VALUES (
        p_return_id,
        p_issued_id,
        v_book_name,
        CURRENT_DATE,
        v_isbn
    );

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS message;
END$$

DELIMITER ;


-- Testing FUNCTION add_return_records
SELECT *
FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT *
FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT *
FROM return_status
WHERE issued_id = 'IS135';

-- Calling Function
CALL add_return_records('RS138', 'IS135');

-- Calling function 
CALL add_return_records('RS148', 'IS140');

DROP PROCEDURE IF EXISTS add_return_records;
SHOW CREATE PROCEDURE add_return_records;
SHOW CREATE PROCEDURE add_return_records;


-- Branch Performance Report
-- Creating a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
CREATE TABLE branch_reports
AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN employees as e
ON e.emp_id = ist.issued_emp_id
JOIN branch as b
ON e.branch_id = b.branch_id
LEFT JOIN return_status as rs
ON rs.issued_id = ist.issued_id
JOIN books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;

SELECT * FROM branch_reports;


-- Create a Table of Active Members
-- To create a new table active_members containing members who have issued at least one book in the last 2 months.

CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE 
                        issued_date >= CURRENT_DATE - INTERVAL 2 year
);

drop table active_members;
SELECT * FROM active_members;

-- Find Employees with the Most Book Issues Processed
-- Query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN employees as e
ON e.emp_id = ist.issued_emp_id
JOIN branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2;



-- Objective: Manage book status during issuance
-- Description:
-- This stored procedure accepts a book_id as input.
-- It checks whether the book is available (status = 'yes').
-- If available, the book is issued and its status is updated to 'no'.
-- If not available, an error/message is returned indicating the book is unavailable.


DELIMITER $$

CREATE PROCEDURE issue_book(
    IN p_issued_id VARCHAR(10),
    IN p_issued_member_id VARCHAR(30),
    IN p_issued_book_isbn VARCHAR(30),
    IN p_issued_emp_id VARCHAR(10)
)
BEGIN
    DECLARE v_status VARCHAR(10);

    -- Check if book is available
    SELECT status
    INTO v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN

        INSERT INTO issued_status (
            issued_id,
            issued_member_id,
            issued_date,
            issued_book_isbn,
            issued_emp_id
        )
        VALUES (
            p_issued_id,
            p_issued_member_id,
            CURRENT_DATE,
            p_issued_book_isbn,
            p_issued_emp_id
        );

        UPDATE books
        SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        SELECT CONCAT(
            'Book issued successfully. ISBN: ',
            p_issued_book_isbn
        ) AS message;

    ELSE
        SELECT CONCAT(
            'Sorry, the requested book is unavailable. ISBN: ',
            p_issued_book_isbn
        ) AS message;
    END IF;

END $$

DELIMITER ;

-- Testing The function
SELECT * FROM books;
SELECT * FROM issued_status;

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8';







