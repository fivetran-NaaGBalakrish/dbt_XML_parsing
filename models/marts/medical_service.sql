{{ config(
    materialized='table'
) }}

select
    medical_service_id,
    product_id,
    xml_position,
    title,
    cover,
    partial

from {{ ref('int_medical_service') }}