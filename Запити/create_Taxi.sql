CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;

CREATE DOMAIN PHONE_NUMBER AS CHAR(13)
    CHECK (VALUE LIKE '+380%');

CREATE TYPE PAYMENT_METHOD AS ENUM ('cash', 'card');

CREATE TABLE Client(
    client_id SERIAL PRIMARY KEY,
    client_login VARCHAR(20) UNIQUE NOT NULL,
    client_password VARCHAR(30) NOT NULL CHECK(length(client_password) >= 6),
    client_address GEOGRAPHY(POINT),
    client_pnumber PHONE_NUMBER NOT NULL
);

CREATE TABLE Driver(
	driver_id SERIAL PRIMARY KEY,
	last_name VARCHAR(20) NOT NULL,
    first_name VARCHAR(20),
	driving_license VARCHAR(10) NOT NULL,
	driver_pnumber PHONE_NUMBER NOT NULL,
	
	-- update_driver_rating_trigger
	driver_rating NUMERIC(2, 1)
);

CREATE TABLE Discount (
    discount_id SERIAL PRIMARY KEY,
    discount_name VARCHAR(20) NOT NULL,
    discount_size NUMERIC(3, 2) NOT NULL CHECK (discount_size >= 0 AND discount_size <= 1)
);

CREATE TABLE Service_type (
    st_id SERIAL PRIMARY KEY,
	service_name VARCHAR(20) NOT NULL,
	price NUMERIC(10, 2) NOT NULL
);

CREATE TABLE Tariff(
	tariff_id SERIAL PRIMARY KEY,
	tariff_name VARCHAR(20) NOT NULL,
	price NUMERIC(10, 2) NOT NULL
);

CREATE TABLE Orders(
	order_id SERIAL PRIMARY KEY,
	date_time TIMESTAMP DEFAULT NOW(),
	departure_point GEOGRAPHY(POINT) NOT NULL,
	destination_point GEOGRAPHY(POINT) NOT NULL,
	payment PAYMENT_METHOD,
	tariff_id INTEGER REFERENCES Tariff(tariff_id) NOT NULL,
	client_id INTEGER REFERENCES Client(client_id) NOT NULL,
	--- set_discount_trigger
	discount_id INTEGER REFERENCES Discount(discount_id)
);

CREATE TABLE Service(
	service_id SERIAL PRIMARY KEY, 
    st_id INTEGER REFERENCES Service_type(st_id) NOT NULL,
    order_id INTEGER REFERENCES Orders(order_id) NOT NULL
);

CREATE TABLE Model(
	model_id SERIAL PRIMARY KEY,
	brand VARCHAR(20) NOT NULL,
	model_name VARCHAR(30) NOT NULL,
	manufacturing_year INTEGER
);

CREATE TABLE Transport(
	transport_id SERIAL PRIMARY KEY,
	model_id INTEGER REFERENCES Model(model_id) NOT NULL,
	tariff_id INTEGER REFERENCES Tariff(tariff_id) NOT NULL,
	plate_number VARCHAR(8) UNIQUE NOT NULL CHECK(length(plate_number) >= 3),
	color VARCHAR(10)
);

CREATE TABLE Ride(
	ride_id SERIAL PRIMARY KEY,
	order_id INTEGER REFERENCES Orders(order_id) UNIQUE NOT NULL,
	driver_id INTEGER REFERENCES Driver(driver_id) NOT NULL,
	ride_time TIMESTAMP DEFAULT NOW(),
		--- calculate_distance_trigger
	distance NUMERIC(10, 2),
		--- calculate_total_price_trigger
	total_price NUMERIC(10, 2),
	transport_id INTEGER REFERENCES Transport(transport_id)
);

CREATE TABLE Feedback(
	feedback_id SERIAL PRIMARY KEY,
	ride_id INTEGER REFERENCES Ride(ride_id) NOT NULL,
	rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
	commentary TEXT
);

SELECT * FROM Client;
SELECT * FROM Driver;
SELECT * FROM Discount;
SELECT * FROM Service_type;
SELECT * FROM Tariff;
SELECT * FROM Orders;
SELECT * FROM Service;
SELECT * FROM Model;
SELECT * FROM Transport;
SELECT * FROM Ride;
SELECT * FROM Feedback;