# 📚 Library Management System – SQL Project

## 📌 Project Overview
The **Library Management System** is a complete MySQL-based database project that manages **library branches, employees, books, members, book issuance, and returns**.

This project demonstrates:
- Proper **ER modeling**
- **Normalized table design**
- **Foreign key relationships**
- **CRUD operations**
- **Advanced SQL queries**
- **Stored procedures**
- **Analytical reports**

Designed specifically for **SQL interviews and portfolio showcase**.

---


## Database Setup
## Table Creation (From Scratch)

### Branch Table
Stores library branch details.

```sql
CREATE TABLE branch (
    branch_id VARCHAR(15) PRIMARY KEY,
    manager_id VARCHAR(15),
    branch_address VARCHAR(50),
    contact_no VARCHAR(15)
);


Employees Table
Stores employees working in each branch.

CREATE TABLE employees (
    emp_id VARCHAR(10) PRIMARY KEY,
    emp_name VARCHAR(30),
    position VARCHAR(30),
    salary DECIMAL(10,2),
    branch_id VARCHAR(10),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

Books Table
Maintains book inventory and availability status.

CREATE TABLE books (
    isbn VARCHAR(50) PRIMARY KEY,
    book_title VARCHAR(80),
    category VARCHAR(30),
    rental_price DECIMAL(10,2),
    status VARCHAR(10),
    author VARCHAR(30),
    publisher VARCHAR(30)
);

Members Table
Stores registered library members.

CREATE TABLE members (
    member_id VARCHAR(10) PRIMARY KEY,
    member_name VARCHAR(30),
    member_address VARCHAR(30),
    reg_date DATE
);

Issued Status Table
Tracks book issue transactions.

CREATE TABLE issued_status (
    issued_id VARCHAR(10) PRIMARY KEY,
    issued_member_id VARCHAR(30),
    issued_book_name VARCHAR(80),
    issued_date DATE,
    issued_book_isbn VARCHAR(50),
    issued_emp_id VARCHAR(10),
    FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
    FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn),
    FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id)
);

Return Status Table
Tracks returned books.

CREATE TABLE return_status (
    return_id VARCHAR(10) PRIMARY KEY,
    issued_id VARCHAR(30),
    return_book_name VARCHAR(80),
    return_date DATE,
    return_book_isbn VARCHAR(50),
    FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);
```
``` SQL
Basic Data Validation

SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM members;
SELECT * FROM issued_status;
SELECT * FROM return_status;
```

## Entity Relationship Diagram

<img width="1263" height="795" alt="Screenshot 2025-12-28 005113" src="https://github.com/user-attachments/assets/4891dacf-01f6-4646-945c-195750f0fc0a" />

## CRUD Operations
**Insert New Book**
```sql
INSERT INTO books
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
```

**Update Member Address**
```sql
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';
```

**Delete Issued Record**
```sql
DELETE FROM issued_status
WHERE issued_id = 'IS121';
```

## 📊 Analytical Queries
**Books Issued by an Employee**
```sql
SELECT issued_id, issued_book_isbn, issued_date
FROM issued_status
WHERE issued_emp_id = 'E101';
```

**Members Who Issued More Than One Book**
```sql
SELECT issued_member_id, COUNT(*) AS total_books
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*) > 1;
```

**Books by Category**
```sql
SELECT * FROM books
WHERE category = 'Classic';
```

**Category-wise Rental Income**
```sql
SELECT b.category, SUM(b.rental_price) AS revenue, COUNT(*) AS total_issues
FROM issued_status ist
JOIN books b ON b.isbn = ist.issued_book_isbn
GROUP BY b.category;
```

**Members Registered in Last 180 Days**
```sql
SELECT *
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL 180 DAY;
```

**Books Not Yet Returned**
```sql
SELECT ist.issued_id, bk.book_title, m.member_name
FROM issued_status ist
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
JOIN books bk ON bk.isbn = ist.issued_book_isbn
JOIN members m ON m.member_id = ist.issued_member_id
WHERE rs.return_id IS NULL;
```

**Overdue Books (30+ Days)**
```sql
SELECT ist.issued_member_id, m.member_name, bk.book_title,
       ist.issued_date,
       CURRENT_DATE - ist.issued_date AS overdue_days
FROM issued_status ist
JOIN members m ON m.member_id = ist.issued_member_id
JOIN books bk ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
AND (CURRENT_DATE - ist.issued_date) > 30;
```

## Stored Procedures (FULL IMPLEMENTATION)
## Issue Book Procedure
**Objective:**
- Check book availability
- Issue book if available
- Update book status
```sql
DELIMITER $$

CREATE PROCEDURE issue_book (
    IN p_issued_id VARCHAR(10),
    IN p_issued_member_id VARCHAR(30),
    IN p_issued_book_isbn VARCHAR(30),
    IN p_issued_emp_id VARCHAR(10)
)
BEGIN
    DECLARE v_status VARCHAR(10);

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

        SELECT 'Book issued successfully' AS message;

    ELSE
        SELECT 'Book is currently unavailable' AS message;
    END IF;

END$$
DELIMITER ;
```

## TESTING – Issue Book Procedure
**Pre-Check Book Status**
```sql
SELECT isbn, status
FROM books
WHERE isbn IN ('978-0-553-29698-2', '978-0-375-41398-8');
```
**Procedure Calls**
```sql
CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');
```
**Validate Issued Records**
```sql
SELECT *
FROM issued_status
WHERE issued_id IN ('IS155', 'IS156');
```
**Validate Book Status Update**
```sql
SELECT isbn, status
FROM books
WHERE isbn IN ('978-0-553-29698-2', '978-0-375-41398-8');
```

## Return Book Procedure
**Objective:**
- Record returned book
- Restore book availability
- 
```sql
DELIMITER $$

CREATE PROCEDURE add_return_records (
    IN p_return_id VARCHAR(10),
    IN p_issued_id VARCHAR(30)
)
BEGIN
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

    SELECT issued_book_isbn, issued_book_name
    INTO v_isbn, v_book_name
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

    SELECT CONCAT('Book returned: ', v_book_name) AS message;
END$$
DELIMITER ;
```

## TESTING – Return Book Procedure
**Validate Issued Records**
```sql
SELECT *
FROM issued_status
WHERE issued_id IN ('IS135', 'IS140');
```
**Procedure Calls**
```sql
CALL add_return_records('RS138', 'IS135');
CALL add_return_records('RS148', 'IS140');
```
**Validate Return Records**
```sql
SELECT *
FROM return_status
WHERE issued_id IN ('IS135', 'IS140');
```
**Validate Book Status Restored**
```sql
SELECT isbn, status
FROM books
WHERE isbn IN (
    SELECT issued_book_isbn
    FROM issued_status
    WHERE issued_id IN ('IS135', 'IS140')
);
```

## Branch Performance Report
```sql
CREATE TABLE branch_reports AS
SELECT b.branch_id, b.manager_id,
       COUNT(ist.issued_id) AS books_issued,
       COUNT(rs.return_id) AS books_returned,
       SUM(bk.rental_price) AS total_revenue
FROM issued_status ist
JOIN employees e ON e.emp_id = ist.issued_emp_id
JOIN branch b ON b.branch_id = e.branch_id
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
JOIN books bk ON bk.isbn = ist.issued_book_isbn
GROUP BY b.branch_id, b.manager_id;
```

## Technologies Used

- MySQL
- ER Diagram Modeling
- Stored Procedures
- Joins & Subqueries
- Date Functions

## Author
**Koonapalli Thulaseeswar - SQL & Database Fresher**



























































