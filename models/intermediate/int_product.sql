{{ config(
    materialized='view'
) }}

{% set product_columns = {
    '@ProductID': {'alias': 'product_id', 'data_type': 'string'},
    '@FundID': {'alias': 'fund_id', 'data_type': 'string'},
    '@ProductCode': {'alias': 'product_code', 'data_type': 'string'},
    '@Iteration': {'alias': 'iteration', 'data_type': 'integer'},
    '@Status': {'alias': 'status', 'data_type': 'string'},
    '@StatusDate': {'alias': 'status_date', 'data_type': 'timestamp'},
    '@DateModified': {'alias': 'date_modified', 'data_type': 'timestamp'},
    '@DateCreated': {'alias': 'date_created', 'data_type': 'timestamp'},
    '@PublishDate': {'alias': 'publish_date_raw', 'data_type': 'string'},
    '@DateApproved': {'alias': 'date_approved', 'data_type': 'timestamp'},
    'FundCode': {'alias': 'fund_code', 'data_type': 'string'},
    'TableCode': {'alias': 'table_code', 'data_type': 'string'},
    'Name': {'alias': 'product_name', 'data_type': 'string'},
    'ProductStatus': {'alias': 'product_status', 'data_type': 'string'},
    'DateValidFrom': {'alias': 'date_valid_from', 'data_type': 'date'},
    'DateIssued': {'alias': 'date_issued', 'data_type': 'date'},
    'State': {'alias': 'state', 'data_type': 'string'},
    'Category': {'alias': 'category', 'data_type': 'string'},
    'ProductType': {'alias': 'product_type', 'data_type': 'string'},
    'MedicareLevySurchargeExempt': {'alias': 'medicare_levy_surcharge_exempt', 'data_type': 'boolean'},
    'PremiumNoRebate': {'alias': 'premium_no_rebate', 'data_type': 'number(12, 2)'},
    'Premium': {'alias': 'premium', 'data_type': 'number(12, 2)'},
    'PremiumHospitalComponent': {'alias': 'premium_hospital_component', 'data_type': 'number(12, 2)'}
} %}

select
    {{ flatten_xml_columns(
        discovery_relation=source('sftp_naag_xml', 'customer_data'),
        discovery_xml_expression="parse_xml(_data)",
        xml_column='xml_data',
        column_config=product_columns,
        exclude=['@xmlns', 'HospitalCover', 'GeneralHealthCover'],
        passthrough_columns=['source_file']
    ) }}

from {{ ref('stg_customer_xml') }}
