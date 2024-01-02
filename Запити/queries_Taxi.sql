--1 Найдовший час очікування кожного водія
EXPLAIN ANALYZE SELECT d.last_name,
	MAX(r.ride_time - date_time) AS arriving_time
FROM Driver d
JOIN Ride r ON r.driver_id=d.driver_id
JOIN Orders o ON o.order_id = r.order_id
GROUP BY d.driver_id, d.last_name;

--2 Середня відстань від домашньої адреси до місця відправлення
EXPLAIN ANALYZE SELECT 
    c.client_login, 
    ROUND(CAST(AVG(COALESCE(ST_Distance(o.departure_point, c.client_address), 0))/1000 
			   AS numeric), 2) AS distance_from_home
FROM 
    Client c
JOIN 
    Orders o ON o.client_id = c.client_id
GROUP BY 
    c.client_login;

--3 Топ 5 водіїв  
EXPLAIN ANALYZE SELECT
    d.driver_rating,
	d.last_name,
    r.total_distance,
    r.total_rides
FROM Driver d
JOIN (
    SELECT
        driver_id,
        SUM(distance) AS total_distance,
        COUNT(*) AS total_rides
    FROM Ride
    GROUP BY driver_id
) r ON d.driver_id = r.driver_id
WHERE d.driver_rating IS NOT NULL
ORDER BY d.driver_rating DESC, total_rides DESC, total_distance DESC
LIMIT 5;


--4 Автомобілі на яких працювали водії
EXPLAIN ANALYZE SELECT 
	d.last_name,
	m.brand,
	m.model_name,
	t.plate_number
FROM Driver d
JOIN Ride r ON d.driver_id = r.driver_id
JOIN Transport t ON r.transport_id = t.transport_id
JOIN Model m ON t.model_id = m.model_id
ORDER BY d.last_name;

--5 Замовлення, ціна яких більша за середню
EXPLAIN ANALYZE SELECT DISTINCT c.client_login, c.client_pnumber
FROM Client c
JOIN Orders o ON o.client_id = c.client_id
JOIN Ride r ON o.order_id = r.order_id
WHERE r.total_price > (SELECT AVG(total_price) FROM Ride);


--6 Автомобіль, який найбільше використовували за рік
EXPLAIN ANALYZE SELECT m.brand,
		m.model_name,
		t.plate_number, 
		COUNT(*) as usage_count
FROM Ride r
JOIN Transport t ON r.transport_id = t.transport_id
JOIN Model m ON t.model_id = m.model_id
WHERE EXTRACT(YEAR FROM ride_time) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY m.brand,
		m.model_name,
		t.plate_number
ORDER BY usage_count DESC
LIMIT 1;

--7 Топ 3 послуги за останні 3 місяці
EXPLAIN ANALYZE SELECT st.service_name, COUNT(s.order_id) AS order_count
FROM Service s
JOIN Service_type st ON s.st_id = st.st_id
JOIN Orders o ON o.order_id = s.order_id 
WHERE o.date_time >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY st.service_name
ORDER BY order_count DESC
LIMIT 3;

--8 Нові автомобілі у компанії
EXPLAIN ANALYZE SELECT  m.brand,
		m.model_name,
		t.plate_number
FROM Model m
JOIN Transport t ON t.model_id = m.model_id
WHERE m.manufacturing_year >= 2010
ORDER BY m.manufacturing_year;

--9 Клієнти, що отримували знижку постійного клієнта
EXPLAIN ANALYZE SELECT DISTINCT c.client_login, 
		c.client_pnumber
FROM Orders o
JOIN Client c ON o.client_id = c.client_id
WHERE discount_id = 1;

--10 Кількість здійснених водієм поїздок влітку  
EXPLAIN ANALYZE SELECT d.first_name, d.last_name, COUNT(*) as ride_count
FROM Ride r
JOIN Driver d ON d.driver_id = r.driver_id
WHERE r.ride_time BETWEEN '2023-06-01 00:01' AND '2023-08-31 23:59'
GROUP BY d.first_name, d.last_name
HAVING COUNT(*) > 0;

--11 Водії, що не виконували замовлення протягом останнього тижня
EXPLAIN ANALYZE SELECT *
FROM Driver
WHERE driver_id NOT IN 
(SELECT DISTINCT driver_id FROM Ride WHERE ride_time >= NOW() - INTERVAL '1 week');

--12 Тарифи, що використвувались минулого місяця
EXPLAIN ANALYZE SELECT *
FROM Tariff t
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
	WHERE o.tariff_id = t.tariff_id
		AND EXTRACT(MONTH FROM o.date_time) = EXTRACT(MONTH FROM CURRENT_DATE)-1
		AND EXTRACT(YEAR FROM o.date_time) = EXTRACT(YEAR FROM CURRENT_DATE)
);

--13 Рейтинг користувачів за середньою вартістю їх поїздок
EXPLAIN ANALYZE SELECT client_id, client_login,
       ROUND(COALESCE((SELECT AVG(total_price) FROM Ride r WHERE r.order_id IN 
					   (SELECT o.order_id FROM Orders o WHERE o.client_id = c.client_id)),0),2) AS avg_ride_cost
FROM Client c
ORDER BY avg_ride_cost DESC;

--14 Рейтинг водіїв за кількістю відгуків
EXPLAIN ANALYZE SELECT driver_id, last_name, first_name, 
       (SELECT COUNT(*) FROM Feedback f WHERE f.ride_id IN (SELECT r.ride_id FROM Ride r 
															WHERE r.driver_id = d.driver_id)) AS feedback_count
FROM Driver d
ORDER BY feedback_count DESC;

--15 Кількість поїздок з новорічною знижкою
EXPLAIN ANALYZE SELECT COUNT(*) AS new_year_discounts
FROM Orders o
JOIN Discount d ON d.discount_id = o.discount_id
WHERE d.discount_name = 'New year';

--16 Середній рейтинг усіх водіїв 
EXPLAIN ANALYZE SELECT
    ROUND(AVG(d.driver_rating), 1) AS average_rating,
    COUNT(DISTINCT r.ride_id) AS ratings
FROM
    Driver d
LEFT JOIN Ride r ON d.driver_id = r.driver_id
JOIN Feedback f ON r.ride_id = f.ride_id
WHERE
    d.driver_rating IS NOT NULL;

--17 Найдовша поїздка за попередній місяць
EXPLAIN ANALYZE SELECT
	d.driver_id,
    d.last_name,
	MAX(r.distance) AS max_distance
FROM
    Ride r
JOIN
    Driver d ON r.driver_id = d.driver_id
WHERE
    EXTRACT(MONTH FROM r.ride_time) = EXTRACT(MONTH FROM CURRENT_DATE)-1
	AND EXTRACT(YEAR FROM r.ride_time) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY
	d.driver_id,
    d.last_name
HAVING MAX(r.distance) = (
	SELECT
		MAX(r_inner.distance)
	FROM
		Ride r_inner
	WHERE
		EXTRACT(MONTH FROM r_inner.ride_time) = EXTRACT(MONTH FROM CURRENT_DATE)-1
		AND EXTRACT(YEAR FROM r_inner.ride_time) = EXTRACT(YEAR FROM CURRENT_DATE));

--18 Кількість поїздок та суми по дням тижня
EXPLAIN ANALYZE SELECT
    EXTRACT(DOW FROM o.date_time) AS day_of_week,
    COUNT(*) AS rides_on_weekdays,
	SUM(r.total_price) AS sum_on_weekdays
FROM Orders o
JOIN Ride r ON o.order_id = r.order_id
WHERE EXTRACT(YEAR FROM o.date_time) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY
    day_of_week
ORDER BY
    day_of_week;

--19 Кількість послуг кожного типу для кожного клієнта
EXPLAIN ANALYZE SELECT
    c.client_id,
    st.service_name,
    COUNT(*) AS service_count
FROM
    Client c
    JOIN Orders o ON c.client_id = o.client_id
    JOIN Service s ON o.order_id = s.order_id
    JOIN Service_type st ON s.st_id = st.st_id
GROUP BY
    c.client_id,
    st.service_name
ORDER BY c.client_id, service_count DESC;


--20 Кількість клієнтів та водіїв, що здійснювали поїздки після 23:00
EXPLAIN ANALYZE SELECT
    COUNT(DISTINCT o.client_id) AS late_clients,
    COUNT(DISTINCT r.driver_id) AS late_drivers
FROM
    Orders o
    LEFT JOIN Ride r ON o.order_id = r.order_id
WHERE
    EXTRACT(HOUR FROM r.ride_time) >= 23;
	
-- 21 Пункти призначення після 23:00
SELECT 
    c.client_login,
	ROUND(CAST(ST_Distance(o.departure_point, c.client_address)/1000 
    AS NUMERIC), 2) AS distance_from_home,
	o.departure_point
FROM Client c
JOIN Orders o ON o.client_id = c.client_id
WHERE c.client_id = 1001
ORDER BY distance_from_home;