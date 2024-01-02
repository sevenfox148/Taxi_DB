--1 Виручка за заданий рік
CREATE OR REPLACE FUNCTION Revenue_Year(work_year INTEGER)
RETURNS NUMERIC(10, 2)
LANGUAGE plpgsql AS $$
DECLARE
    total_revenue NUMERIC(10, 2);
BEGIN
    SELECT SUM(total_price) INTO total_revenue
    FROM Ride
    WHERE EXTRACT(YEAR FROM ride_time) = work_year;

    RETURN total_revenue;
END $$;

SELECT Revenue_Year(2023) AS total_revenue;

--2 Виведення відгуків до заданого водія
CREATE OR REPLACE FUNCTION Drivers_Feedback(given_driver INTEGER)
RETURNS SETOF Feedback AS
$$
    SELECT f.*
    FROM Feedback f
    JOIN Ride r ON f.ride_id = r.ride_id
    WHERE r.driver_id = given_driver
	ORDER BY f.rating DESC;
$$ LANGUAGE SQL;

SELECT * FROM Drivers_Feedback(11);

--3 Порівняння оплат картою і готівкою
CREATE OR REPLACE PROCEDURE Cash_vs_Card()
AS $$
DECLARE
    cash_count INTEGER;
    card_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO cash_count
    FROM Orders
    WHERE payment = 'cash';
    
    SELECT COUNT(*) INTO card_count
    FROM Orders
    WHERE payment = 'card';

    IF card_count > cash_count THEN
        RAISE NOTICE 'More used cards for payment: %', card_count;
    ELSE
        RAISE NOTICE 'More used cash for payment: %', cash_count;
    END IF;
END $$ LANGUAGE plpgsql;

CALL Cash_vs_Card();

--4 Вирахування штрафу водія за місяць
CREATE OR REPLACE FUNCTION Driver_Fine(driver INTEGER, work_month INTEGER)
RETURNS NUMERIC(10, 2)
LANGUAGE plpgsql AS $$
DECLARE
    fine NUMERIC(10, 2);
BEGIN
    SELECT
	SUM ((EXTRACT(EPOCH FROM (r.ride_time - o.date_time)) / 60)-10)*2
	INTO fine
	FROM Ride r 
	JOIN Orders o ON o.order_id = r.order_id
	WHERE EXTRACT(MONTH FROM ride_time) = work_month
			AND EXTRACT(YEAR FROM ride_time) = EXTRACT(YEAR FROM CURRENT_DATE)
			AND driver_id = driver
			AND EXTRACT(EPOCH FROM (r.ride_time - o.date_time)) / 60 > 10;
	
    RETURN fine;
END $$;

SELECT Driver_Fine(6, 7) AS drivers_fine;
			
--5 Зарплата водія за заданий місяць (з урахуванням штрафів)
CREATE OR REPLACE FUNCTION Driver_Salary(driver INTEGER, work_month INTEGER)
RETURNS NUMERIC(10, 2)
LANGUAGE plpgsql AS $$
DECLARE
    salary NUMERIC(10, 2);
BEGIN
    SELECT SUM(total_price)*0.2 INTO salary
    FROM Ride
    WHERE EXTRACT(MONTH FROM ride_time) = work_month
			AND EXTRACT(YEAR FROM ride_time) = EXTRACT(YEAR FROM CURRENT_DATE)
			AND driver_id = driver;
    RETURN salary - Driver_Fine(driver, work_month);
END $$;

SELECT last_name,
		Driver_Salary(driver_id, EXTRACT(MONTH FROM CURRENT_DATE)::INTEGER) 
		AS drivers_salary
FROM Driver
ORDER BY last_name;

--6 Кількість водіїв з ретингом більше заданного
CREATE OR REPLACE FUNCTION High_Rated_Drivers(min_rating NUMERIC(2, 1))
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM Driver WHERE driver_rating >= min_rating);
END;
$$ LANGUAGE plpgsql;

SELECT High_Rated_Drivers(3) AS high_rated_drivers;

--7 Найбільш вживана послуга за поточний рік
CREATE OR REPLACE FUNCTION Most_Used_Service()
RETURNS VARCHAR(20) AS $$
BEGIN
    RETURN (SELECT st.service_name
            FROM Service s
            JOIN Service_type st ON s.st_id = st.st_id
            JOIN Orders o ON o.order_id = s.order_id
            WHERE EXTRACT(YEAR FROM o.date_time) = EXTRACT(YEAR FROM NOW())
            GROUP BY st.service_name
            ORDER BY COUNT(s.order_id) DESC
            LIMIT 1);
END;
$$ LANGUAGE plpgsql;

SELECT EXTRACT(YEAR FROM NOW()) AS current_year, Most_Used_Service() AS most_used_service;

--8 Вивести список послуг для усіх замовлень
CREATE OR REPLACE PROCEDURE Order_Services_Info(order_i INTEGER)
AS $$
DECLARE
    service_name_i TEXT;
BEGIN
    RAISE NOTICE 'Order ID: %', order_i;
	FOR service_name_i IN SELECT st.service_name
		FROM Service s
		JOIN Service_type st ON s.st_id = st.st_id
		WHERE s.order_id = order_i
        LOOP
            RAISE NOTICE 'Service: %', service_name_i;
        END LOOP;
END $$ LANGUAGE plpgsql;

CALL Order_Services_Info(2005);

--9 Оновити посвічення водія
CREATE OR REPLACE PROCEDURE Update_Driving_Licennse(driver_i INTEGER, new_driving_license VARCHAR(20))
AS $$
BEGIN
    UPDATE Driver
    SET driving_license = new_driving_license
    WHERE driver_id = driver_i;
	RAISE NOTICE 'New driver licence is %', new_driving_license;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM Driver WHERE driver_id = 4;
CALL Update_Driving_Licennse(4, '00777890');

--10 Видалення замовлення
CREATE OR REPLACE PROCEDURE Delete_Order(order_i INTEGER)
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Orders WHERE order_id = order_i) THEN
        RAISE EXCEPTION 'Order with specified order_id does not exist.';
    END IF;

    IF EXISTS (SELECT 1 FROM Ride WHERE order_id = order_i) THEN
        RAISE EXCEPTION 'Cannot delete order with associated ride.';
    ELSE    
		DELETE FROM Service WHERE order_id = order_i;
        DELETE FROM Orders WHERE order_id = order_i;
        RAISE NOTICE 'Order #% deleted', order_i;
    END IF;
END;
$$ LANGUAGE plpgsql;

CALL Delete_Order(60001);