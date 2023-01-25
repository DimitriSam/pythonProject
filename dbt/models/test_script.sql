select cus.name, cus.last_name, date_created , amoun from customers cus
inner Join transaction tr ON tr.id = cus.customer_id
