{{ config(
    materialized='view'
) }}

with source as (

    select
        get(xml_data, '@ProductID')::string as product_id,

        xmlget(
            xmlget(xml_data, 'HospitalCover'),
            'Excesses'
        ) as excess_xml

    from {{ ref('stg_customer_xml') }}

)

select

    product_id,

    get(excess_xml, '@ExcessType')::string
        as excess_type,

    get(
        xmlget(excess_xml, 'ExcessPerAdmission'),
        '$'
    )::number as excess_per_admission,

    get(
        xmlget(excess_xml, 'ExcessPerPolicy'),
        '$'
    )::number as excess_per_policy

from source