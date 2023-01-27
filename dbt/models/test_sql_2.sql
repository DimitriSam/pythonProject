SELECT cus.name
FROM customers cus
INNER JOIN employees em ON em.id = cus.id
ON em.date = cus.date

