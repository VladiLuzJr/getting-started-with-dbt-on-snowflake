{{ config(alias='ORDERS_SECURE_VW') }}
select *
from {{ ref('orders') }}
