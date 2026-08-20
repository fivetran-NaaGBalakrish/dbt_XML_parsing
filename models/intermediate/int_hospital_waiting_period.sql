{{ config(
    materialized='view'
) }}

with source as (

    select
        get(xml_data, '@ProductID')::string as product_id,

        xmlget(
            xmlget(xml_data, 'HospitalCover'),
            'WaitingPeriods'
        ) as waiting_periods_xml

    from {{ ref('stg_customer_xml') }}

),

flattened as (

    select
        s.product_id,
        f.index as xml_position,
        f.value as waiting_period_xml

    from source s,

    lateral flatten(
        input => get(s.waiting_periods_xml, '$')
    ) f

    where get(f.value, '@')::string = 'WaitingPeriod'

)

select

    hash(
        product_id,
        get(waiting_period_xml, '@Title')::string,
        get(waiting_period_xml, '@Unit')::string
    ) as waiting_period_id,

    product_id,

    xml_position,

    get(waiting_period_xml, '@Title')::string
        as title,

    get(waiting_period_xml, '@Unit')::string
        as unit,

    get(waiting_period_xml, '$')::integer
        as waiting_period_value

from flattened