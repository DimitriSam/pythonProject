select
    cus.name,
    cus.last_name,
    cus.email,
    cus.date_created,
    cus.amount,
    tr.transaction_date
from customers as cus
inner join transaction as tr on tr.id = cus.customer_id
