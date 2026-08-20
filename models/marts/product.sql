{{ config(
    materialized='table'
) }}

select *
from {{ ref('int_product') }}