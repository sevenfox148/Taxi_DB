--Створення ролей
CREATE ROLE taxi_admin_role;
CREATE ROLE driver_role;
CREATE ROLE client_rode;


-- ДОДАТИ ДОЗВІЛ ДО Sequences
GRANT SELECT ON TABLE Client, Orders, Service, Feedback, Service_type,
					Tariff, Transport, Ride TO client_rode;
GRANT INSERT, DELETE ON TABLE Orders, Service, Feedback TO client_rode;
GRANT UPDATE ON TABLE Client, Orders TO client_rode;
GRANT USAGE, SELECT ON SEQUENCE orders_order_id_seq, service_service_id_seq, feedback_feedback_id_seq TO client_rode;

GRANT SELECT ON TABLE Client, Orders, Service, Feedback, Service_type,
					Tariff, Transport, Model, Driver, Ride, Discount TO driver_role;
GRANT INSERT ON TABLE Ride TO driver_role;
GRANT USAGE, SELECT ON SEQUENCE ride_ride_id_seq TO driver_role;

GRANT INSERT ON TABLE Transport, Model, Driver, Discount, Service_type, Tariff TO taxi_admin_role;
GRANT UPDATE ON TABLE Driver, Discount, Service_type, Tariff TO taxi_admin_role;
GRANT SELECT ON TABLE Client, Orders, Service, Feedback, Service_type,
					Tariff, Transport, Model, Driver, Ride, Discount TO taxi_admin_role;
GRANT USAGE, SELECT ON SEQUENCE transport_transport_id_seq, model_model_id_seq, driver_driver_id_seq, 
	discount_discount_id_seq, service_type_st_id_seq, tariff_tariff_id_seq TO taxi_admin_role;


CREATE USER "db_admin" WITH PASSWORD 'long_password';
CREATE USER "driver1" WITH PASSWORD 'medium_password';
CREATE USER "client1" WITH PASSWORD 'short_password';

GRANT taxi_admin_role TO "db_admin";
GRANT driver_role TO "driver1";
GRANT client_rode TO "client1";

SELECT usename, rolname FROM pg_user JOIN pg_auth_members ON (pg_user.usesysid = pg_auth_members.member) 
JOIN pg_roles ON (pg_roles.oid = pg_auth_members.roleid);

SET ROLE client1;
SET ROLE db_admin;

INSERT INTO Driver(last_name, first_name, driving_license, driver_pnumber)
VALUES ('Nelson', 'Johanna', 'DL30894', '+380667852383');