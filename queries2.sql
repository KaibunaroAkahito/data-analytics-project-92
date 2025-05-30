-- Отчет: Топ-10 продавцов по суммарной выручке
-- Выводит имя продавца, количество сделок и общую выручку
-- Сортировка по убыванию выручки
SELECT TRIM(CONCAT(employees.first_name, ' ', COALESCE(employees.middle_initial || ' ', ''),
                   employees.last_name))           AS seller,
       COUNT(sales.sales_id)                       AS operations,
       FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
         JOIN employees ON sales.sales_person_id = employees.employee_id
         JOIN products ON sales.product_id = products.product_id
GROUP BY employees.employee_id, employees.first_name, employees.middle_initial, employees.last_name
ORDER BY income DESC
LIMIT 10;


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
