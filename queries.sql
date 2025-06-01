--- Запрос на получение общего количества покупателей. Без учета уникальных!
SELECT COUNT(customer_id) AS customers_count FROM customers;

-- Отчет: Топ-10 продавцов по суммарной выручке
-- Выводит имя продавца, количество сделок и общую выручку
-- Сортировка по убыванию выручки
SELECT TRIM(CONCAT(employees.first_name, ' ', employees.last_name)) AS seller,
       COUNT(sales.sales_id)                                        AS operations,
       FLOOR(SUM(products.price * sales.quantity))                  AS income
FROM sales
         JOIN employees ON sales.sales_person_id = employees.employee_id
         JOIN products ON sales.product_id = products.product_id
GROUP BY employees.employee_id, employees.first_name, employees.middle_initial, employees.last_name
ORDER BY income DESC
LIMIT 10


-- Отчет о продавцах со средней выручкой ниже средней по всем продавцам
-- Выводит имя продавца, среднию выручку продавца за сделку с округлением до целого
WITH seller_stats AS (SELECT CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
                             FLOOR(AVG(products.price * sales.quantity))            AS average_income
                      FROM sales
                               JOIN products ON sales.product_id = products.product_id
                               JOIN employees ON employees.employee_id = sales.sales_person_id
                      GROUP BY seller),
     overall_avg AS (SELECT FLOOR(AVG(products.price * sales.quantity)) AS avg_income
                     FROM sales
                              JOIN products ON sales.product_id = products.product_id
                              JOIN employees ON employees.employee_id = sales.sales_person_id)
SELECT seller,
       average_income
FROM seller_stats
WHERE average_income < (SELECT avg_income FROM overall_avg)
ORDER BY average_income ASC;



-- Отчет: данные по выручке по каждому продавцу и дню недели
-- Выводит имя продавца, день нели и суммарную выручку продавца в определенный день недели, округленная до целого числа
-- Сортировка по убыванию выручки
SELECT CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
       LOWER(TO_CHAR(sales.sale_date, 'day'))                 AS day_of_week,
       FLOOR(SUM(products.price * sales.quantity))            AS income
FROM sales
         JOIN products ON sales.product_id = products.product_id
         JOIN employees ON employees.employee_id = sales.sales_person_id
GROUP BY seller, day_of_week
ORDER BY EXTRACT(DOW FROM MIN(sale_date)), -- Сортировка по порядку дня недели
         seller;

-- Возрастные группы покупателей
SELECT CASE
           WHEN age BETWEEN 16 AND 25 THEN '16-25'
           WHEN age BETWEEN 26 AND 40 THEN '26-40'
           WHEN age > 40 THEN '40+'
           END  AS age_category,
       COUNT(*) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category;

-- Покупатели и выручка по месяцам
SELECT TO_CHAR(sale_date, 'YYYY-MM')               AS date,
       COUNT(DISTINCT customer_id)                 AS total_customers,
       FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
         JOIN products ON sales.product_id = products.product_id
         JOIN employees ON employees.employee_id = sales.sales_person_id
GROUP BY date
ORDER BY date ASC;

-- Покупатели с первой покупкой по акции
SELECT DISTINCT ON (customers.customer_id) CONCAT(customers.first_name, ' ', customers.last_name) AS customer,
                                           first_purchase.first_sale_date,
                                           CONCAT(employees.first_name, ' ', employees.last_name) AS seller
FROM customers
         JOIN (SELECT customer_id,
                      MIN(sale_date) AS first_sale_date
               FROM sales
               GROUP BY customer_id) first_purchase ON customers.customer_id = first_purchase.customer_id
         JOIN
     sales ON first_purchase.customer_id = sales.customer_id
         AND first_purchase.first_sale_date = sales.sale_date
         JOIN
     products ON sales.product_id = products.product_id
         JOIN
     employees ON sales.sales_person_id = employees.employee_id
WHERE products.price = 0
ORDER BY customers.customer_id;
