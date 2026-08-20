{{ config(
    materialized='view'
) }}

select
    _file as source_file,
    _data as raw_xml,
    {{ parse_xml_document('_data') }} as xml_data

from {{ source('sftp_naag_xml', 'customer_data') }}
