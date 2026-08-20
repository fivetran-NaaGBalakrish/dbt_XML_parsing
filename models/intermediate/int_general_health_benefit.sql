{{ config(
    materialized='view'
) }}

with services as (

    select
        general_health_service_id,
        product_id,
        title as service_title,
        service_xml

    from {{ ref('int_general_health_service') }}

),

benefits as (

    select

        s.general_health_service_id,
        s.product_id,
        s.service_title,

        f.index as xml_position,
        f.value as benefit_xml

    from services s,

    lateral flatten(
        input => get(
            xmlget(s.service_xml, 'BenefitsList'),
            '$'
        ),
        outer => true
    ) f

    where get(f.value, '@')::string = 'Benefit'

)

select

    hash(
        general_health_service_id,
        get(benefit_xml, '@Item')::string
    ) as benefit_id,

    general_health_service_id,

    product_id,

    xml_position,

    service_title,

    get(benefit_xml, '@Item')::string
        as item,

    get(benefit_xml, '@Type')::string
        as benefit_type,

    get(benefit_xml, '$')::number
        as benefit_value

from benefits