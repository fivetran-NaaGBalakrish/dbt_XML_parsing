{{ config(
    materialized='table'
) }}

select
    general_health_service_id,
    product_id,
    xml_position,
    title,
    covered,
    has_special_features,
    waiting_period,
    benefit_limits_group

from {{ ref('int_general_health_service') }}