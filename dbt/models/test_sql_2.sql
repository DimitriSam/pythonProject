SELECT cus.name
FROM customers cus
INNER JOIN employees em ON em.id = cus.id;
--put some text here that denotes the change AFTER PR;