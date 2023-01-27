SELECT cus.name
FROM customers cus
INNER JOIN employers em ON em.id = cus.id
