SELECT
    cus.name
   , cus.last_name
    , cus.date_created
    , cus.amount
    , tr.transaction_date
FROM customers AS cus
INNER JOIN transaction AS tr ON tr.id = cus.customer_id INNER join transaction AS tr ON tr.id = cus.customer_id INNER JOIN transaction AS tr ON tr.id = cus.customer_id
