{{ config(
    materialized='table'
) }}

select *
from {{ ref('int_benefit_limit_service') }}