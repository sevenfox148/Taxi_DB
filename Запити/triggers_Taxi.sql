-- тригер для призначення знижки
CREATE OR REPLACE FUNCTION condition_discount2(client INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    oder_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO oder_count
    FROM Orders
    WHERE client_id = client;

    RETURN (oder_count + 1) % 10 = 0;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION condition_discount1(client INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (
        EXISTS (
            SELECT 1
            FROM Orders
            WHERE
                client_id = client
                AND date_time >= current_date - interval '3 months'
            GROUP BY client_id
            HAVING COUNT(*)+1 >= 15
        )
    );
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION set_discount_function()
RETURNS TRIGGER AS $$
DECLARE
    discount_id_value INTEGER;
BEGIN
	IF (EXTRACT(MONTH FROM NEW.date_time) = 12
		AND EXTRACT(DAY FROM NEW.date_time) = 31) THEN
		discount_id_value := 3;
    -- Перевірка умови condition_discount1
    ELSIF condition_discount1(NEW.client_id) THEN
        discount_id_value := 1;
    -- Перевірка умови condition_discount2
    ELSIF condition_discount2(NEW.client_id) THEN
        discount_id_value := 2;
    ELSE
        discount_id_value := NULL;  -- Не відповідає жодній умові
    END IF;

    NEW.discount_id := discount_id_value;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_discount_trigger
BEFORE INSERT ON Orders
FOR EACH ROW
EXECUTE FUNCTION set_discount_function();

-- тригер для обрахунку рейтингу
CREATE OR REPLACE FUNCTION update_driver_rating()
RETURNS TRIGGER AS $$
DECLARE
    avg_rating NUMERIC(2, 1);
    update_driver_id INTEGER;
BEGIN
	SELECT r.driver_id
	INTO update_driver_id
	FROM Feedback f
	JOIN Ride r ON f.ride_id = r.ride_id
	WHERE f.feedback_id = NEW.feedback_id;

    SELECT AVG(f.rating)::NUMERIC(2, 1)
    INTO avg_rating
    FROM Feedback f
    JOIN Ride r ON f.ride_id = r.ride_id
    WHERE r.driver_id = update_driver_id;

    UPDATE Driver
    SET driver_rating = avg_rating
    WHERE driver_id = update_driver_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_driver_rating_trigger
AFTER INSERT ON Feedback
FOR EACH ROW
EXECUTE FUNCTION update_driver_rating();

-- тригер для обрахунку відстані
CREATE OR REPLACE FUNCTION calculate_distance()
RETURNS TRIGGER AS $$
DECLARE
    calc_distance NUMERIC(10, 2);
BEGIN
    SELECT ST_Distance(o.departure_point, o.destination_point)/1000
	INTO calc_distance
    FROM Orders o
    WHERE o.order_id = NEW.order_id;
	
	UPDATE Ride
    SET distance = calc_distance
    WHERE ride_id = NEW.ride_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_distance_trigger
AFTER INSERT ON Ride
FOR EACH ROW
EXECUTE FUNCTION calculate_distance();

DROP TRIGGER calculate_distance_trigger ON Ride;

-- тригер для обрахунку вартості
CREATE OR REPLACE FUNCTION calculate_total_price()
RETURNS TRIGGER AS $$
DECLARE
    calc_distance NUMERIC(10, 2);
	tariff_price NUMERIC(10, 2);
	services_sum NUMERIC(10, 2);
	discount_s NUMERIC(3, 2);
	
BEGIN
	SELECT ST_Distance(o.departure_point, o.destination_point)/1000 INTO calc_distance
	FROM Orders o
	WHERE o.order_id = NEW.order_id;
	
	SELECT t.price INTO tariff_price
	FROM Orders o
	JOIN Tariff t ON t.tariff_id = o.tariff_id
	WHERE o.order_id = NEW.order_id;
	
	SELECT COALESCE(SUM(st.price), 0) INTO services_sum
	FROM Orders o
	JOIN Service s ON o.order_id = s.order_id
	JOIN Service_type st ON s.st_id = st.st_id
	WHERE o.order_id = NEW.order_id;
	
	SELECT COALESCE(d.discount_size, 0) INTO discount_s
	FROM Orders o
	LEFT JOIN Discount d ON d.discount_id = o.discount_id
	WHERE o.order_id = NEW.order_id;
	
	UPDATE Ride
	SET total_price = (calc_distance*tariff_price + services_sum)*(1-discount_s)
	WHERE ride_id = NEW.ride_id;
	
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_total_price_trigger
AFTER INSERT ON Ride
FOR EACH ROW
EXECUTE FUNCTION calculate_total_price();

-- тригер відповідності тарифів
CREATE OR REPLACE FUNCTION check_tariff_match()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT tariff_id FROM Orders WHERE order_id = NEW.order_id) != 
	(SELECT tariff_id FROM Transport WHERE transport_id = NEW.transport_id) THEN
        RAISE EXCEPTION 'Tariff mismatch between order and transport';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_tariff_match_trigger
BEFORE INSERT ON Ride
FOR EACH ROW
EXECUTE FUNCTION check_tariff_match();

-- Видалення водія з високим рейтингом
CREATE OR REPLACE FUNCTION prevent_delete_high_rated_driver_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT driver_rating FROM Driver WHERE driver_id = OLD.driver_id) >= 4.0 THEN
        RAISE EXCEPTION 'Cannot delete driver with high rating';
	ELSE
		DELETE
		FROM Feedback f
		WHERE f.ride_id IN(
			SELECT r.ride_id 
			FROM Ride r 
			WHERE r.driver_id = OLD.driver_id);
		
		DELETE FROM Ride WHERE driver_id = OLD.driver_id;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_delete_high_rated_driver
BEFORE DELETE ON Driver
FOR EACH ROW
EXECUTE FUNCTION prevent_delete_high_rated_driver_trigger();

-- Оновлення рейтингу після видалення відгуку
CREATE OR REPLACE FUNCTION del_update_driver_rating()
RETURNS TRIGGER AS $$
DECLARE
    avg_rating NUMERIC(2, 1);
    update_driver_id INTEGER;
BEGIN
	SELECT r.driver_id
	INTO update_driver_id
	FROM Feedback f
	JOIN Ride r ON f.ride_id = r.ride_id
	WHERE f.feedback_id = OLD.feedback_id;

    SELECT AVG(f.rating)::NUMERIC(2, 1)
    INTO avg_rating
    FROM Feedback f
    JOIN Ride r ON f.ride_id = r.ride_id
    WHERE r.driver_id = update_driver_id;

    UPDATE Driver
    SET driver_rating = avg_rating
    WHERE driver_id = update_driver_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER del_update_driver_rating_trigger
AFTER DELETE ON Feedback
FOR EACH ROW
EXECUTE FUNCTION del_update_driver_rating();

-- Зміна паролю
CREATE OR REPLACE FUNCTION validate_client_password_length()
RETURNS TRIGGER AS $$
BEGIN
    IF LENGTH(NEW.client_password) < 6 THEN
        RAISE EXCEPTION 'Client password must be at least 6 characters long.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_new_client_password
BEFORE UPDATE ON Client
FOR EACH ROW
EXECUTE FUNCTION validate_client_password_length();

UPDATE Client
SET client_password='HSF'
WHERE client_id = 1003;

SELECT client_password FROM Client
WHERE client_id = 1003;

-- Дата
CREATE OR REPLACE FUNCTION calculate_time()
RETURNS TRIGGER AS $$
DECLARE
    order_date TIMESTAMP;
BEGIN
    SELECT o.date_time
    INTO order_date 
    FROM Orders o
    WHERE o.order_id = NEW.order_id;
	
    UPDATE Ride
    SET ride_time = order_date + (FLOOR(random() * (25 - 3 + 1) + 3) || ' minutes')::INTERVAL
    WHERE ride_id = NEW.ride_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_time_trigger
AFTER INSERT ON Ride
FOR EACH ROW
EXECUTE FUNCTION calculate_time(); 

DROP TRIGGER calculate_time_trigger ON Ride;

-- Рандомний транспорт
CREATE OR REPLACE FUNCTION choose_transport()
RETURNS TRIGGER AS $$
DECLARE
    order_tariff INTEGER;
	transport_num INTEGER;
BEGIN
    SELECT o.tariff_id
    INTO order_tariff 
    FROM Orders o
    WHERE o.order_id = NEW.order_id;
	
	SELECT transport_id
	INTO transport_num
	FROM Transport
	WHERE tariff_id = order_tariff
	ORDER BY RANDOM() LIMIT 1;

    UPDATE Ride
    SET transport_id = transport_num 
    WHERE ride_id = NEW.ride_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER choose_transport_trigger
AFTER INSERT ON Ride
FOR EACH ROW
EXECUTE FUNCTION choose_transport();

DROP TRIGGER choose_transport_trigger ON Ride;