-- Середня ціна поїздки за місяць
CREATE OR REPLACE VIEW Ride_Cost_Sum_PerMonth AS
SELECT
    EXTRACT(MONTH FROM ride_time) AS month_,
    ROUND(SUM(total_price), 2) AS sum_ride_cost
FROM
    Ride
WHERE 
	EXTRACT(YEAR FROM ride_time) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY
    month_
ORDER BY 
	month_;

DROP VIEW Ride_Cost_Sum_PerMonth
SELECT * FROM Ride_Cost_Sum_PerMonth;


-- Водій, що виконав найбільше поїздок
CREATE OR REPLACE VIEW Driver_Max_Rides AS
SELECT
    d.last_name AS driver_last_name,
    COUNT(r.ride_id) AS total_rides
FROM
    Driver d
    JOIN Ride r ON d.driver_id = r.driver_id
WHERE EXTRACT(YEAR FROM r.ride_time) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY
    d.last_name
ORDER BY
    total_rides DESC
LIMIT 1;

SELECT * FROM Driver_Max_Rides;


-- Водії, що не проводили поїздок 3 тижні та мають рейтинг менше 4
CREATE OR REPLACE VIEW Firing_List AS
SELECT *
FROM Driver
WHERE driver_id NOT IN 
(SELECT DISTINCT driver_id FROM Ride WHERE ride_time >= NOW() - INTERVAL '3 week')
AND (driver_rating < 4 OR driver_rating IS NULL);

SELECT * FROM Firing_List;