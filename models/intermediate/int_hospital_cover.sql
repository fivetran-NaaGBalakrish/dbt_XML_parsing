{{ config(
    materialized='view'
) }}

with source as (

    select
        get(xml_data, '@ProductID')::string as product_id,
        xmlget(xml_data, 'HospitalCover') as hospital_xml

    from {{ ref('stg_customer_xml') }}

)

select

    product_id,

    get(hospital_xml, '@GapCoverProvided')::boolean
        as gap_cover_provided,

    get(
        xmlget(hospital_xml, 'ClassificationHospital'),
        '$'
    )::string as classification_hospital,

    get(
        xmlget(hospital_xml, 'Accommodation'),
        '$'
    )::string as accommodation,

    get(
        xmlget(hospital_xml, 'HospitalAmbulance'),
        '$'
    )::string as hospital_ambulance,

    get(
        xmlget(hospital_xml, 'OtherProductFeatures'),
        '$'
    )::string as other_product_features

from source