--- Запрос на получение общего количества покупателей. Без учета уникальных!
SELECT COUNT(customer_id) AS customers_count FROM customers;

-- Отчет: Топ-10 продавцов по суммарной выручке
-- Выводит имя продавца, количество сделок и общую выручку
-- Сортировка по убыванию выручки
SELECT
    TRIM(CONCAT(employees.first_name, ' ', employees.last_name)) AS seller,
    COUNT(sales.sales_id) AS operations,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
INNER JOIN employees ON sales.sales_person_id = employees.employee_id
INNER JOIN products ON sales.product_id = products.product_id
GROUP BY
    seller
ORDER BY income DESC
LIMIT 10;

-- Отчет о продавцах со средней выручкой ниже средней по всем продавцам
-- Выводит имя продавца, среднию выручку продавца за сделку с округлением 
-- до целого
WITH seller_stats AS (
    SELECT
        CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
        FLOOR(AVG(products.price * sales.quantity)) AS average_income,
        FLOOR(AVG(AVG(products.price * sales.quantity)) OVER ()) AS overall_avg_income
    FROM sales
    INNER JOIN products ON sales.product_id = products.product_id
    INNER JOIN employees ON sales.sales_person_id = employees.employee_id
    GROUP BY seller
)

SELECT
    seller_stats.seller,
    seller_stats.average_income
FROM seller_stats
WHERE average_income < overall_avg_income
ORDER BY average_income ASC;

-- Отчет: данные по выручке по каждому продавцу и дню недели
-- Выводит имя продавца, день нели и суммарную выручку продавца 
-- в определенный день недели, округленная до целого числа
-- Сортировка по убыванию выручки
SELECT
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
    LOWER(TRIM(TO_CHAR(sales.sale_date, 'day'))) AS day_of_week,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
INNER JOIN products ON sales.product_id = products.product_id
INNER JOIN employees ON sales.sales_person_id = employees.employee_id
-- сомнительно...
GROUP BY
    seller,
    TRIM(TO_CHAR(sales.sale_date, 'day')),
    EXTRACT(ISODOW FROM sales.sale_date)
ORDER BY EXTRACT(ISODOW FROM sales.sale_date), seller;

-- Возрастные группы покупателей
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category;

-- Покупатели и выручка по месяцам
SELECT
    TO_CHAR(sales.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT sales.customer_id) AS total_customers,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
INNER JOIN products ON sales.product_id = products.product_id
INNER JOIN employees ON sales.sales_person_id = employees.employee_id
GROUP BY selling_month
ORDER BY selling_month ASC;

-- Покупатели с первой покупкой по акции
WITH first_purchase AS (
    SELECT
        sales.customer_id,
        MIN(sales.sale_date) AS sale_date
    FROM sales
    GROUP BY sales.customer_id
)

SELECT DISTINCT ON (customers.customer_id)
    first_purchase.sale_date,
    CONCAT(customers.first_name, ' ', customers.last_name) AS customer,
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller
FROM customers
INNER JOIN first_purchase
    ON customers.customer_id = first_purchase.customer_id
INNER JOIN
    sales
    ON
        first_purchase.customer_id = sales.customer_id
        AND first_purchase.sale_date = sales.sale_date
INNER JOIN
    products ON sales.product_id = products.product_id
INNER JOIN
    employees ON sales.sales_person_id = employees.employee_id
WHERE products.price = 0
ORDER BY customers.customer_id;
