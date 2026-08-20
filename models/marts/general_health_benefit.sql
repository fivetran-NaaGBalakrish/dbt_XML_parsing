{{ config(
    materialized='table'
) }}

select *
from {{ ref('int_general_health_benefit') }}