select
    cus.name,
    cus.last_name,
    cus.date_created,
    tr.amount
from customers as cus
inner join transaction as tr on tr.id = cus.customer_id
