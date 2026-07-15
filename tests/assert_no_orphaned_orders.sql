-- Fails if any order line lost its customer or product match during the
-- staging join (would surface as a null after the left join upstream).

select order_id
from {{ ref('fact_orders') }}
where customer_id is null
   or product_id is null
