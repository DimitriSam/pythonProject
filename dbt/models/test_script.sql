SELECT
    cus.name
    , cus.last_name
    , cus.date_created
    , tr.amount
    , tr.transaction_date
FROM customers AS cus
INNER JOIN transactions AS tr ON cus.customer_id = tr.id
WHERE (cus.date_created < NOW() - 1 AND tr.amount > 10 AND tr.amount IS NOT NULL);
--put some text here that denotes the change before PR
