{{ config(
    materialized='view'
) }}

with source as (

    select
        get(xml_data, '@ProductID')::string as product_id,

        xmlget(
            xmlget(xml_data, 'HospitalCover'),
            'MedicalServices'
        ) as medical_services_xml

    from {{ ref('stg_customer_xml') }}

),

flattened as (

    select
        s.product_id,
        f.index as xml_position,
        f.value as medical_service_xml

    from source s,

    lateral flatten(
        input => get(s.medical_services_xml, '$')
    ) f

    where get(f.value, '@')::string = 'MedicalService'

)

select

    hash(
        product_id,
        get(medical_service_xml, '@Title')::string
    ) as medical_service_id,

    product_id,

    xml_position,

    get(medical_service_xml, '@Title')::string
        as title,

    get(medical_service_xml, '@Cover')::string
        as cover,

    get(medical_service_xml, '@Partial')::boolean
        as partial

from flattened