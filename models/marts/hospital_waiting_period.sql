{{ config(
    materialized='table'
) }}

select *
from {{ ref('int_hospital_waiting_period') }}