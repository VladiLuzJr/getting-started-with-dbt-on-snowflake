{{ config(alias='SALES_METRICS_BY_LOCATION_SECURE_VW') }}
select *
from {{ ref('sales_metrics_by_location') }}
