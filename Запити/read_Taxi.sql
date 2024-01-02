TRUNCATE TABLE Feedback, Ride, Transport, Model, Service, Orders, Tariff, Service_type, Discount, Driver, Client;

COPY Client FROM 'C:\taxi\client.csv' WITH CSV HEADER DELIMITER ';';
COPY Driver FROM 'C:\taxi\driver.csv' WITH CSV HEADER DELIMITER ';';
COPY Discount FROM 'C:\taxi\discount.csv' WITH CSV HEADER DELIMITER ';';
COPY Service_type FROM 'C:\taxi\service_type.csv' WITH CSV HEADER DELIMITER ';';
COPY Tariff FROM 'C:\taxi\tariff.csv' WITH CSV HEADER DELIMITER ';';
COPY Orders FROM 'C:\taxi\orders.csv' WITH CSV HEADER DELIMITER ';';
COPY Service FROM 'C:\taxi\service.csv' WITH CSV HEADER DELIMITER ';';
COPY Model FROM 'C:\taxi\model.csv' WITH CSV HEADER DELIMITER ';';
COPY Transport FROM 'C:\taxi\transport.csv' WITH CSV HEADER DELIMITER ';';
COPY Ride FROM 'C:\taxi\ride.csv' WITH CSV HEADER DELIMITER ';';
COPY Feedback FROM 'C:\taxi\feedback.csv' WITH CSV HEADER DELIMITER ';';