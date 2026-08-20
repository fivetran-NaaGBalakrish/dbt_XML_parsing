{{ config(
    materialized='table'
) }}

select *
from {{ ref('int_hospital_cover') }}