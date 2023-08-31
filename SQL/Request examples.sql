/*
Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Facebook*.
*(сервис, запрещённый на территории РФ)
*/

WITH base AS 
(SELECT p.id,
COUNT(e.instituition)
FROM people AS p
RIGHT JOIN education AS e ON p.id = e.person_id
WHERE p.company_id IN
(SELECT id
FROM company
WHERE name = 'Facebook')
GROUP BY p.id)
SELECT AVG(COUNT)
FROM base;

/*
Составьте таблицу из полей:
name_of_fund — название фонда;
name_of_company — название компании;
amount — сумма инвестиций, которую привлекла компания в раунде.
В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, а раунды финансирования проходили с 2012 по 2013 год включительно.
*/

SELECT f.name AS name_of_fund,
c.name AS name_of_company,
fr.raised_amount AS amount
FROM investment AS i
LEFT JOIN company AS c ON c.id = i.company_id
LEFT JOIN fund AS f ON i.fund_id = f.id
INNER JOIN 
(SELECT*
FROM funding_round
WHERE funded_at BETWEEN '2012-01-01' AND '2013-12-31')
AS fr ON fr.id = i.funding_round_id
WHERE c.milestones > 6;

/*
Выгрузите таблицу, в которой будут такие поля:
название компании-покупателя;
сумма сделки;
название компании, которую купили;
сумма инвестиций, вложенных в купленную компанию;
доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.
Не учитывайте те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы. 
*/

WITH acquiring AS
(SELECT c.name AS buyer,
a.price_amount AS price,
a.id AS KEY
FROM acquisition AS a
LEFT JOIN company AS c ON a.acquiring_company_id = c.id
WHERE a.price_amount > 0),
acquired AS
(SELECT c.name AS acquisition,
c.funding_total AS investment,
a.id AS KEY
FROM acquisition AS a
LEFT JOIN company AS c ON a.acquired_company_id = c.id
WHERE c.funding_total > 0)
SELECT acqn.buyer,
acqn.price,
acqd.acquisition,
acqd.investment,
ROUND(acqn.price / acqd.investment) AS uplift
FROM acquiring AS acqn
JOIN acquired AS acqd ON acqn.KEY = acqd.KEY
ORDER BY price DESC, acquisition
LIMIT 10;

/*
Выгрузите таблицу, в которую войдут названия компаний из категории social, получившие финансирование с 2010 по 2013 год включительно. 
Проверьте, что сумма инвестиций не равна нулю. Выведите также номер месяца, в котором проходил раунд финансирования.
*/

SELECT  c.name AS social_co,
EXTRACT (MONTH FROM fr.funded_at) AS funding_month
FROM company AS c
LEFT JOIN funding_round AS fr ON c.id = fr.company_id
WHERE c.category_code = 'social'
AND fr.funded_at BETWEEN '2010-01-01' AND '2013-12-31'
AND fr.raised_amount <> 0;

/*
Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
номер месяца, в котором проходили раунды;
количество уникальных названий фондов из США, которые инвестировали в этом месяце;
количество компаний, купленных за этот месяц;
общая сумма сделок по покупкам в этом месяце.
*/

WITH fundings AS
(SELECT EXTRACT(MONTH FROM CAST(fr.funded_at AS DATE)) AS funding_month,
COUNT(DISTINCT f.id) AS us_funds
FROM fund AS f
LEFT JOIN investment AS i ON f.id = i.fund_id
LEFT JOIN funding_round AS fr ON i.funding_round_id = fr.id
WHERE f.country_code = 'USA'
AND EXTRACT(YEAR FROM CAST(fr.funded_at AS DATE)) BETWEEN 2010 AND 2013
GROUP BY funding_month),
acquisitions AS
(SELECT EXTRACT(MONTH FROM CAST(acquired_at AS DATE)) AS funding_month,
COUNT(acquired_company_id) AS bought_co,
SUM(price_amount) AS sum_total
FROM acquisition
WHERE EXTRACT(YEAR FROM CAST(acquired_at AS DATE)) BETWEEN 2010 AND 2013
GROUP BY funding_month)
SELECT fnd.funding_month, fnd.us_funds, acq.bought_co, acq.sum_total
FROM fundings AS fnd
LEFT JOIN acquisitions AS acq ON fnd.funding_month = acq.funding_month;

/*
Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. 
Данные за каждый год должны быть в отдельном поле. Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему.
*/

WITH y_11 AS
(SELECT country_code AS country,
AVG(funding_total) AS y_2011
FROM company
WHERE EXTRACT(YEAR FROM founded_at::DATE) IN(2011, 2012, 2013)
GROUP BY country, EXTRACT(YEAR FROM founded_at)
HAVING EXTRACT(YEAR FROM founded_at) = '2011'),
y_12 AS
(SELECT country_code AS country,
AVG(funding_total) AS y_2012
FROM company
WHERE EXTRACT(YEAR FROM founded_at::DATE) IN(2011, 2012, 2013)
GROUP BY country, EXTRACT(YEAR FROM founded_at)
HAVING EXTRACT(YEAR FROM founded_at) = '2012'),
y_13 AS
(SELECT country_code AS country,
AVG(funding_total) AS y_2013
FROM company
WHERE EXTRACT(YEAR FROM founded_at::DATE) IN(2011, 2012, 2013)
GROUP BY country, EXTRACT(YEAR FROM founded_at)
HAVING EXTRACT(YEAR FROM founded_at) = '2013')
SELECT y_11.country, y_2011, y_2012, y_2013
FROM y_11
JOIN y_12 ON y_11.country = y_12.country
JOIN y_13 ON y_12.country = y_13.country
ORDER BY y_2011 DESC;
