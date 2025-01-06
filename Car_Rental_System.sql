-- Create Table for Customers
CREATE TABLE customers (
    customer_id NUMBER PRIMARY KEY,
    name VARCHAR2(100),
    phone_number VARCHAR2(15) UNIQUE,
    email VARCHAR2(100) UNIQUE
);

-- Create Table for Cars
CREATE TABLE cars (
    car_id NUMBER PRIMARY KEY,
    model VARCHAR2(100),
    registration_number VARCHAR2(50) UNIQUE,
    daily_rental_rate NUMBER,
    availability VARCHAR2(10) CHECK (availability IN ('Available', 'Booked'))
);

-- Create Table for Bookings
CREATE TABLE bookings (
    booking_id NUMBER PRIMARY KEY,
    customer_id NUMBER REFERENCES customers(customer_id),
    car_id NUMBER REFERENCES cars(car_id),
    booking_date DATE,
    return_date DATE,
    total_cost NUMBER,
    CONSTRAINT chk_booking_date CHECK (return_date > booking_date)
);


-- Insert entries into Customers
INSERT INTO customers VALUES (1, 'Amit Patil', '1234567890', 'amit12@gmail.com');
INSERT INTO customers VALUES (2, 'Bhavik Patil', '9876543210', 'bhavik12@gmail.com');
select * from Customers;

-- Insert entries Cars
INSERT INTO cars VALUES (1, 'Toyota Corolla', 'MH12AB1234', 1000, 'Available');
INSERT INTO cars VALUES (2, 'Honda City', 'MH12CD5678', 1200, 'Available');
select * from Cars;

-- Insert entries into Bookings
INSERT INTO bookings VALUES (1, 1, 1, TO_DATE('2025-01-01', 'YYYY-MM-DD'), TO_DATE('2025-01-05', 'YYYY-MM-DD'), NULL);
select * from Bookings;

--Trigger for Updating Car Availability
CREATE OR REPLACE TRIGGER update_car_availability
AFTER INSERT OR DELETE ON bookings
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE cars
        SET availability = 'Booked'
        WHERE car_id = :NEW.car_id;
    ELSIF DELETING THEN
        UPDATE cars
        SET availability = 'Available'
        WHERE car_id = :OLD.car_id;
    END IF;
END;
/

--Function to Calculate Rental Cost
CREATE OR REPLACE FUNCTION calculate_rental_cost(
    p_car_id NUMBER,
    p_duration NUMBER
) RETURN NUMBER IS
    v_daily_rate NUMBER;
    v_total_cost NUMBER;
BEGIN
    SELECT daily_rental_rate
    INTO v_daily_rate
    FROM cars
    WHERE car_id = p_car_id;

    v_total_cost := v_daily_rate * p_duration;
    RETURN v_total_cost;
END;
/

--Query to Identify Frequently Rented Cars
SELECT c.model, COUNT(b.car_id) AS rental_count
FROM bookings b
JOIN cars c ON b.car_id = c.car_id
GROUP BY c.model
ORDER BY rental_count DESC;
--Create sequence to generate unique booking id
CREATE SEQUENCE bookings_seq START WITH 1 INCREMENT BY 1;

--Procedure to Book a Car and Update Total Cost
CREATE OR REPLACE PROCEDURE book_car(
    p_customer_id NUMBER,
    p_car_id NUMBER,
    p_booking_date DATE,
    p_return_date DATE
) IS
    v_duration NUMBER;
    v_total_cost NUMBER;
BEGIN
    v_duration := p_return_date - p_booking_date;
    v_total_cost := calculate_rental_cost(p_car_id, v_duration);

    INSERT INTO bookings (booking_id, customer_id, car_id, booking_date, return_date, total_cost)
    VALUES (bookings_seq.NEXTVAL, p_customer_id, p_car_id, p_booking_date, p_return_date, v_total_cost);

    DBMS_OUTPUT.PUT_LINE('Car booked successfully. Total cost: ' || v_total_cost);
END;
/

--An anonymous plsql block for testing
BEGIN
    book_car(
        p_customer_id => 1,
        p_car_id => 2,
        p_booking_date => TO_DATE('2025-01-07', 'YYYY-MM-DD'),
        p_return_date => TO_DATE('2025-01-10', 'YYYY-MM-DD')
    );
END;
/
select * from Bookings;
