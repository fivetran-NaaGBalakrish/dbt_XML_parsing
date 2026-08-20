{{ config(
    materialized='view'
) }}

with source as (

    select

        get(xml_data, '@ProductID')::string
            as product_id,

        xmlget(
            xmlget(xml_data, 'GeneralHealthCover'),
            'BenefitLimits'
        ) as benefit_limits_xml

    from {{ ref('stg_customer_xml') }}

),

flattened as (

    select

        s.product_id,
        f.index as xml_position,
        f.value as benefit_limit_xml

    from source s,

    lateral flatten(
        input => get(s.benefit_limits_xml, '$')
    ) f

    where get(f.value, '@')::string = 'BenefitLimit'

)

select

    hash(
        product_id,
        get(benefit_limit_xml, '@Title')::string
    ) as benefit_limit_id,

    product_id,

    xml_position,

    get(benefit_limit_xml, '@Title')::string
        as title,

    get(
        benefit_limit_xml,
        '@NoLimitOnPreventativeDental'
    )::boolean as no_limit_on_preventative_dental,

    get(
        xmlget(benefit_limit_xml, 'LimitPerPerson'),
        '$'
    )::number as limit_per_person,

    benefit_limit_xml

from flattened