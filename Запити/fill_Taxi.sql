CREATE OR REPLACE FUNCTION Generate_Point()
RETURNS TEXT AS $$
BEGIN
    RETURN 'POINT(' || CAST(random() * (31.0 - 30.3) + 30.3 AS NUMERIC(10, 4)) || ' ' || 
						 CAST(random() * (50.6 - 50.3) + 50.3 AS NUMERIC(10, 4)) || ')';
END;
$$ LANGUAGE plpgsql;

INSERT INTO Client (client_login, client_password, client_address, client_pnumber) 
VALUES ('runc1827', '73nuedb0', ST_GeographyFromText(Generate_Point()), '+6207863523');

INSERT INTO Discount (discount_name, discount_size)
VALUES
	('Regular client', 0.15),
	('10th order', 0.05),
	('New year', 0.24),
	('Weekend Special', 0.10),
    ('Holiday Promo', 0.18),
    ('Early Bird Offer', 0.12),
    ('Summer Savings', 0.15),
    ('Student Discount', 0.08),
    ('Family Package', 0.20),
    ('Flash Sale', 0.15),
    ('Senior Citizen', 0.10),
    ('Birthday Bonus', 0.05),
    ('Referral Reward', 0.12),
    ('Spring Fling', 0.15),
    ('Corporate Deal', 0.18),
    ('Valentines', 0.14),
    ('Back-to-School', 0.10),
    ('Frequent Rider', 0.15),
    ('Winter Wonderland', 0.20),
    ('Black Friday', 0.25);
	
	
INSERT INTO Service_type (service_name, price)
VALUES
	('Child Seat', 20.00),
	('Towing Service', 50.00),
	('Pet Transportation', 30.00),
	('Event Transportation', 50.00),
	('Delivery', 20.00),
	('Airport Shuttle', 25.00),
	('Luxury Car Upgrade', 20.00),
	('Express Delivery', 12.00),
	('Bicycle Rack', 8.00),
	('Car Wash', 18.00),
	('Night Surcharge', 15.00),
    ('VIP Escort', 40.00),
    ('EV Upgrade', 25.00),
    ('Grocery Delivery', 15.00),
    ('City Tour', 30.00),
    ('Inter-City Transfer', 60.00),
    ('Business Upgrade', 35.00),
    ('Parcel Courier', 15.00),
    ('Multilingual Driver', 20.00),
    ('Cargo Box', 10.00);


INSERT INTO Tariff (tariff_name, price)
VALUES
	('Economy', 10.00),
	('Standard', 15.00),
	('Comfort', 20.00),
	('Business', 25.00),
	('Universal', 18.00),
	('Minibus', 30.00),
	('Premium', 20.00),
	('Luxury', 30.00),
	('Express', 18.00),
    ('City', 12.00),
    ('Night', 14.00),
    ('Day', 16.00),
    ('Weekend', 22.00),
    ('Holiday', 28.00),
    ('Family', 32.00),
    ('Single', 17.00),
    ('RoundTrip', 26.00),
    ('Hourly', 19.00),
	('SuperSaver', 8.00),
    ('UltraPremium', 35.00),
    ('WeekdaySpecial', 14.50),
    ('Adventurer', 21.00),
    ('QuickRide', 12.50);


INSERT INTO Client (client_login, client_password, client_address, client_pnumber)
VALUES
    ('Olligathor', 'dR6*9K}z0Q', ST_GeographyFromText(Generate_Point()), '+380123456789'),
    ('yaroslaviynev', 'oI0+pIX', ST_GeographyFromText(Generate_Point()), '+380987654321'),
    ('Tcinn', 'cN3)sc(', ST_GeographyFromText(Generate_Point()), '+380555555555'),
    ('lisard148', 'rO7{Xw/3Y', ST_GeographyFromText(Generate_Point()), '+380111122233'),
    ('irakum', 'tY7!q$kZk!Dw', ST_GeographyFromText(Generate_Point()), '+380444433322'),
    ('renamed_user07665', 'gP6&U5T<x$', ST_GeographyFromText(Generate_Point()), '+380999988877'),
    ('sky1609', 'iV86bbf', ST_GeographyFromText(Generate_Point()), '+380777766655'),
    ('milrusy', 'pyA6+?Lk', ST_GeographyFromText(Generate_Point()), '+380888877766'),
    ('DmitriyNizhnik', 'vM7=/?@', ST_GeographyFromText(Generate_Point()), '+38012348765'),
    ('Liliok9', 'xJ4!eaQC', ST_GeographyFromText(Generate_Point()), '+38098761234');
	
COPY Client (client_login, client_password, client_pnumber) 
FROM 'C:\taxi\client_generated.csv' WITH CSV HEADER DELIMITER ',';


COPY Driver (last_name, first_name, driving_license, driver_pnumber) 
FROM 'C:\taxi\driver_generated.csv' WITH CSV HEADER DELIMITER ',';


SELECT * FROM Transport
WHERE tariff_id != (
	SELECT tariff_id FROM Orders
	WHERE order_id = 60001);

INSERT INTO Orders (departure_point, destination_point, payment, tariff_id, client_id, date_time)
SELECT
    ST_GeographyFromText(Generate_Point()),
    ST_GeographyFromText(Generate_Point()),
    CASE WHEN random() < 0.5 THEN 'cash'::payment_method ELSE 'card'::payment_method END,
    FLOOR(random() * 6) + 1,
    FLOOR(random() * (SELECT COUNT(*) FROM Client) + 1),
	date_trunc('minute', NOW() - random() * INTERVAL '9 month')
FROM generate_series(1, 1);

INSERT INTO Orders (departure_point, destination_point, payment, tariff_id, client_id, date_time)
SELECT
    ST_GeographyFromText(Generate_Point()),
    ST_GeographyFromText(Generate_Point()),
    CASE WHEN random() < 0.5 THEN 'cash'::payment_method ELSE 'card'::payment_method END,
    FLOOR(random() * 6) + 1,
    FLOOR(random() * (SELECT COUNT(*) FROM Client) + 1),
	'2023-12-31 22:59'
FROM generate_series(1, 1);

INSERT INTO Orders (departure_point, destination_point, payment, tariff_id, client_id, date_time)
SELECT
    ST_GeographyFromText(Generate_Point()),
    ST_GeographyFromText(Generate_Point()),
    CASE WHEN random() < 0.5 THEN 'cash'::payment_method ELSE 'card'::payment_method END,
    FLOOR(random() * 6) + 1,
    1001,
	date_trunc('minute', NOW() - random() * INTERVAL '3 month')
FROM generate_series(1, 16);


INSERT INTO Service (st_id, order_id)
SELECT
    FLOOR(random() * (SELECT COUNT(*) FROM Service_type) + 1),
    FLOOR(random() * (60000 - 8001 + 1) + 8001)
FROM generate_series(1, 50000);

COPY Model (brand, model_name, manufacturing_year) 
FROM 'C:\taxi\model_generated.csv' WITH CSV HEADER DELIMITER ',';


COPY Transport (model_id, tariff_id, plate_number, color) 
FROM 'C:\taxi\transport_generated.csv' WITH CSV HEADER DELIMITER ',';


INSERT INTO Ride (order_id, driver_id)
SELECT
    order_i, 
	FLOOR(random() * (SELECT COUNT(*) FROM Driver) + 1)
FROM generate_series(8001, 60000) AS order_i;


COPY Feedback (ride_id, rating, commentary) 
FROM 'C:\taxi\feedback_generated.csv' WITH CSV HEADER DELIMITER ',';
SELECT COUNT(*) FROM Feedback;

INSERT INTO Feedback (ride_id, rating)
SELECT
    FLOOR(random() * (SELECT COUNT(*) FROM Ride) + 1),
    FLOOR(random() * (5 - 4) + 1)
FROM generate_series(1, 60000);