{{ config(
    materialized='view'
) }}

with limits as (

    select

        benefit_limit_id,
        product_id,
        title as benefit_limit_title,
        benefit_limit_xml

    from {{ ref('int_benefit_limit') }}

),

services_combined as (

    select

        benefit_limit_id,
        product_id,
        benefit_limit_title,

        xmlget(
            benefit_limit_xml,
            'ServicesCombined'
        ) as services_xml

    from limits

),

flattened as (

    select

        s.benefit_limit_id,
        s.product_id,
        s.benefit_limit_title,

        f.index as xml_position,
        f.value as service_xml

    from services_combined s,

    lateral flatten(
        input => get(s.services_xml, '$')
    ) f

    where get(f.value, '@')::string = 'Service'

)

select

    hash(
        benefit_limit_id,
        xml_position,
        get(service_xml, '$')::string
    ) as benefit_limit_service_id,

    benefit_limit_id,

    product_id,

    benefit_limit_title,

    xml_position,

    get(service_xml, '$')::string
        as service_name,

    get(service_xml, '@SubLimitsApply')::boolean
        as sub_limits_apply

from flattened