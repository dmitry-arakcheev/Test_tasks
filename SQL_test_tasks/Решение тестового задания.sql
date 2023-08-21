/* Задание.

У вас SQL база с таблицами:
1) Users(userId, age)
2) Purchases (purchaseId, userId, itemId, date)
3) Items (itemId, price).

Напишите SQL запросы для расчета следующих метрик:
А) какую сумму в среднем в месяц тратит:
- пользователи в возрастном диапазоне от 18 до 25 лет включительно;
- пользователи в возрастном диапазоне от 26 до 35 лет включительно.
Б) в каком месяце года выручка от пользователей в возрастном диапазоне 35+ самая большая.
В) какой товар обеспечивает дает наибольший вклад в выручку за последний год.
Г) топ-3 товаров по выручке и их доля в общей выручке за любой год.

Будет здорово, если ваше решение оформлено в виде работающего кода и основательно протестировано на придуманных данных (код для наполнения данными тоже приложите).
Для тестирования можно использовать онлайн-редактор https://sqliteonline.com/
Предпочтительный диалект - PostgreSQL, но можете использовать любой из доступных. */

/* ________________________________________________________________ */

/* Решение */

/* Сперва создадим 3 таблицы и наполним их произвольными данными. */

CREATE TABLE Users (userID VARCHAR, age INT); /* создаем таблицу Users */

INSERT INTO Users (userID, age) VALUES 
('user' || generate_series(1, 1001),
 trunc(random()*50 + 18)); /* добавляем в таблицу Users данные: 1001 пользователя с возрастом от 18 до 68 лет */


CREATE TABLE Purchases (purchaseID VARCHAR, userID VARCHAR, itemID VARCHAR, date DATE); /* создаем таблицу Purchases */

INSERT INTO Purchases (purchaseID, userID, itemID, date) VALUES 
('purch' || generate_series(1, 110000),
 'user' || trunc(random()*1000 + 1),
 'item' || trunc(random()*100 + 1),
 to_timestamp(1262304000 + trunc(random() * 100000000))::DATE ); /* добавляем в таблицу Purchases данные. Даты между 2010-01-01 и 2013-03-03. Чтобы не усложнять, 1 покупка = 1 вещь. Всего 110000 покупок */  


CREATE TABLE Items (itemID VARCHAR, price INT); /* создаем таблицу Items */

INSERT INTO Items (itemID, price) VALUES 
('item' || generate_series(1, 101),
 trunc(random()*500 + 30)); /* добавляем в таблицу Items данные: 101 вещь с ценой от 30 до 530 рублей */

/* ________________________________________________________________ */

/* А) какую сумму в среднем в месяц тратит:
- пользователи в возрастном диапазоне от 18 до 25 лет включительно;
- пользователи в возрастном диапазоне от 26 до 35 лет включительно. */

WITH ages_purchases AS (SELECT
							CASE
    						WHEN age BETWEEN 18 AND 25 THEN '18-25 лет'
    						WHEN age BETWEEN 26 AND 35 THEN '26-35 лет'
   							WHEN age > 35 THEN '35+ лет'
    						END AS ages,
    						DATE_PART('year', date) as year,
    						DATE_PART('month', date) as month,
    						price
						FROM
							purchases
    						INNER JOIN users USING(userid)
    						INNER JOIN items USING(itemid)
                       ),  /* 1 подзапрос - определяем каждого пользователя в группу в соответствии с возрастом, для удобства выделяем год и месяц, определяем траты */
ages_spendings AS (SELECT
						ages,
    					year,
    					month,
    					SUM(price) as spendings
					FROM
						ages_purchases
					GROUP BY
						ages,
    					year,
    					month) /* 2 подзапрос - группируем данные из 1го подзапроса по группам пользователей, годам и месяцам в году */
 SELECT
 	ages,
    ROUND(AVG(spendings), 2) as avg_month_spendings
 FROM
 	ages_spendings
 GROUP BY
 	ages; /* рассчитываем средние траты в месяц для каждой возрастной группы  */

/* ________________________________________________________________ */

/* Б) в каком месяце года выручка от пользователей в возрастном диапазоне 35+ самая большая */

/* не совсем понятно, что конкретно требуется найти, поэтому представляю 2 варианта */

/* 1 вариант. Выведем группу пользователей 35+ лет и их траты по каждому месяцу каждого года в порядке убывания */

WITH ages_purchases AS (SELECT
							CASE
    						WHEN age BETWEEN 18 AND 25 THEN '18-25 лет'
    						WHEN age BETWEEN 26 AND 35 THEN '26-35 лет'
   							WHEN age > 35 THEN '35+ лет'
    						END AS ages,
    						DATE_PART('year', date) as year,
    						DATE_PART('month', date) as month,
    						price
						FROM
							purchases
    						INNER JOIN users USING(userid)
    						INNER JOIN items USING(itemid)
                       ), /* 1 подзапрос - определяем каждого пользователя в группу в соответствии с возрастом, для удобства выделяем год и месяц, определяем траты */
ages_spendings AS (SELECT
						ages,
    					year,
    					month,
    					SUM(price) as spendings
					FROM
						ages_purchases
					GROUP BY
						ages,
    					year,
    					month) /* 2 подзапрос - группируем данные из 1го подзапроса по группам пользователей, годам и месяцам в году */
 SELECT
 	*
 FROM
 	ages_spendings
WHERE
	ages = '35+ лет'
ORDER BY
	spendings DESC,
    month;
	
/* 2 вариант. Выведем группу пользователей 35+ лет и их средние траты по месяцам в порядке убывания*/

WITH ages_purchases AS (SELECT
							CASE
    						WHEN age BETWEEN 18 AND 25 THEN '18-25 лет'
    						WHEN age BETWEEN 26 AND 35 THEN '26-35 лет'
   							WHEN age > 35 THEN '35+ лет'
    						END AS ages,
    						DATE_PART('year', date) as year,
    						DATE_PART('month', date) as month,
    						price
						FROM
							purchases
    						INNER JOIN users USING(userid)
    						INNER JOIN items USING(itemid)
                       ), /* 1 подзапрос - определяем каждого пользователя в группу в соответствии с возрастом, для удобства выделяем год и месяц, определяем траты */
ages_spendings AS (SELECT
						ages,
    					year,
    					month,
    					SUM(price) as spendings
					FROM
						ages_purchases
					GROUP BY
						ages,
    					year,
    					month) /* 2 подзапрос - группируем данные из 1го подзапроса по группам пользователей, годам и месяцам в году */
 SELECT
 	ages,
    month,
    ROUND(AVG(spendings), 2) as avg_spendings
 FROM
 	ages_spendings
WHERE
	ages = '35+ лет'
GROUP BY
	ages,
    month
ORDER BY
	avg_spendings DESC,
    month;

/* ________________________________________________________________ */

/* B) Товар, который дает наибольший вклад в выручку за последний год */

/* в качестве последнего года беру последний полный год - 2012 */

SELECT
	itemid,
    SUM(price) as revenue
FROM
	purchases 
    INNER JOIN items USING(itemid)
WHERE
	date BETWEEN '2012-01-01' AND '2013-01-01'
GROUP BY
	itemid
ORDER BY
	2 DESC
LIMIT 1;

/* или чуть более заковыристый вариант */

WITH items_revenue_2012 AS (SELECT
								p.itemid as item,
								SUM(price) AS revenue_2012
							FROM
								purchases p 
								INNER JOIN items i USING(itemid)
							WHERE
								DATE_PART('year', date) = 2012
							GROUP BY
								1)
SELECT
	item,
    revenue_2012,
    ROUND(100 * revenue_2012 / SUM(revenue_2012) OVER(), 2) AS revenue_percent
FROM
	items_revenue_2012
ORDER BY
	revenue_percent DESC
LIMIT 1;

/* ________________________________________________________________ */

/* Г) топ-3 товаров по выручке и их доля в общей выручке за любой год */

/* топ-3 товаров по выручке */

SELECT
	itemid
FROM
	purchases 
	INNER JOIN items USING(itemid)
GROUP BY
	itemid
ORDER BY
	SUM(price) DESC
LIMIT 3;

/* а теперь всё вместе */

WITH top_3_items AS (SELECT
						itemid
					FROM
						purchases 
    				INNER JOIN items USING(itemid)
					GROUP BY
						itemid
					ORDER BY
						SUM(price) DESC
					LIMIT 3), /* топ-3 товаров по выручке */
revenue_per_year AS (SELECT
						itemid,
    					DATE_PART('year', date) AS year,
    					SUM(price) as revenue
					FROM
						purchases
    					INNER JOIN items USING(itemid)
					GROUP BY
						1, 2), /* выручка каждого товара по годам */
revenue_percentage AS (SELECT
							itemid,
							year,
							ROUND(100*revenue / SUM(revenue) OVER(PARTITION BY year), 2) AS revenue_percent
					   FROM
							revenue_per_year) /* доля выручки каждого товара по годам */
SELECT
	itemid,
    year,
    revenue_percent
FROM
	revenue_percentage
WHERE
	itemid in (SELECT * FROM top_3_items)
ORDER BY
	year,
    revenue_percent DESC; /* доля выручки топ-3 товаров по годам */