{{ config(
    materialized='view'
) }}

with source as (

    select

        get(xml_data, '@ProductID')::string
            as product_id,

        xmlget(
            xmlget(xml_data, 'GeneralHealthCover'),
            'GeneralHealthServices'
        ) as services_xml

    from {{ ref('stg_customer_xml') }}

),

flattened as (

    select
        s.product_id,
        f.index as xml_position,
        f.value as service_xml

    from source s,

    lateral flatten(
        input => get(s.services_xml, '$')
    ) f

    where get(f.value, '@')::string = 'GeneralHealthService'

)

select

    hash(
        product_id,
        get(service_xml, '@Title')::string
    ) as general_health_service_id,

    product_id,

    xml_position,

    get(service_xml, '@Title')::string
        as title,

    get(service_xml, '@Covered')::integer
        as covered,

    get(service_xml, '@HasSpecialFeatures')::integer
        as has_special_features,

    get(
        xmlget(service_xml, 'WaitingPeriod'),
        '$'
    )::integer as waiting_period,

    get(
        xmlget(service_xml, 'BenefitLimitsGroup'),
        '$'
    )::string as benefit_limits_group,

    /*
       Keep XML because the benefit model
       needs the BenefitsList child.
    */
    service_xml

from flattened