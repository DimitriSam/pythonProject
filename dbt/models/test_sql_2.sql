SELECT cus.name
FROM customers cus
INNER JOIN employees em ON em.id = cus.id
--I want to check again that nothing is running before the PR;