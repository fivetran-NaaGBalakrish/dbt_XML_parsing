{{ config(
    materialized='view'
) }}

with source as (

    select
        get(xml_data, '@ProductID')::string as product_id,
        xmlget(xml_data, 'GeneralHealthCover') as gh_xml

    from {{ ref('stg_customer_xml') }}

)

select

    product_id,

    get(
        xmlget(gh_xml, 'ClassificationGeneralHealth'),
        '$'
    )::string as classification_general_health,

    get(
        xmlget(gh_xml, 'GeneralHealthAmbulance'),
        '@Cover'
    )::string as ambulance_cover,

    get(
        xmlget(gh_xml, 'OtherProductFeatures'),
        '$'
    )::string as other_product_features,

    get(
        xmlget(gh_xml, 'SpecialFeatures'),
        '$'
    )::string as special_features

from source