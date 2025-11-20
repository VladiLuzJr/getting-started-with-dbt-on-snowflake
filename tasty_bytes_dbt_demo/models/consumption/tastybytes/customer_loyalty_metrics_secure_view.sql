{{ config(alias='CUSTOMER_LOYALTY_METRICS_SECURE_VW') }}
select *
from {{ ref('customer_loyalty_metrics') }}
