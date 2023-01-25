select cus.name, cus.last_name,date_created , amount from customers cus
inner Join transaction tr ON tr.id = cus.customer_id
