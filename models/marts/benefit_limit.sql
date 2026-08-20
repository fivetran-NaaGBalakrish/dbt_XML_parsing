{{ config(
    materialized='table'
) }}

select
    benefit_limit_id,
    product_id,
    xml_position,
    title,
    no_limit_on_preventative_dental,
    limit_per_person

from {{ ref('int_benefit_limit') }}