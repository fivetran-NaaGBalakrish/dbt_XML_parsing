{% macro parse_xml_document(xml_expression) -%}
    parse_xml({{ xml_expression }})
{%- endmacro %}


{% macro xml_key_to_column_name(xml_key) -%}
    {%- set clean_key = xml_key[1:] if xml_key[:1] == '@' else xml_key -%}
    {%- set result = namespace(value='') -%}

    {%- for character in clean_key -%}
        {%- set is_upper = character == character | upper and character != character | lower -%}

        {%- if not loop.first -%}
            {%- set previous_character = clean_key[loop.index0 - 1] -%}
            {%- set next_character = clean_key[loop.index0 + 1] if not loop.last else '' -%}
            {%- set previous_is_lower = previous_character == previous_character | lower and previous_character != previous_character | upper -%}
            {%- set previous_is_digit = previous_character in '0123456789' -%}
            {%- set previous_is_upper = previous_character == previous_character | upper and previous_character != previous_character | lower -%}
            {%- set next_is_lower = next_character == next_character | lower and next_character != next_character | upper -%}

            {%- if is_upper and (previous_is_lower or previous_is_digit or (previous_is_upper and next_is_lower)) -%}
                {%- set result.value = result.value ~ '_' -%}
            {%- endif -%}
        {%- endif -%}

        {%- set result.value = result.value ~ character | lower -%}
    {%- endfor -%}

    {{- result.value -}}
{%- endmacro %}


{% macro flatten_xml_columns(
    discovery_relation,
    discovery_xml_expression,
    xml_column,
    column_config={},
    exclude=[],
    passthrough_columns=[]
) %}

    {% set discovery_query %}
        with xml_documents as (

            select {{ discovery_xml_expression }} as xml_document
            from {{ discovery_relation }}

        ),

        discovered_columns as (

            select
                attribute.key::string as xml_key,
                'attribute' as xml_kind,
                typeof(attribute.value) as value_type

            from xml_documents,
                lateral flatten(input => xml_document) as attribute

            where attribute.key::string like '@%'
                and attribute.key::string != '@'

            union all

            select
                get(child.value, '@')::string as xml_key,
                'element' as xml_kind,
                typeof(get(child.value, '$')) as value_type

            from xml_documents,
                lateral flatten(input => get(xml_document, '$')) as child

            where is_object(child.value)

        )

        select
            xml_key,
            xml_kind,
            listagg(distinct value_type, ',')
                within group (order by value_type) as value_types

        from discovered_columns

        {% if exclude | length > 0 %}
            where xml_key not in (
                {% for xml_key in exclude %}
                    '{{ xml_key | replace("'", "''") }}'{% if not loop.last %},{% endif %}
                {% endfor %}
            )
        {% endif %}

        group by
            xml_key,
            xml_kind

        order by
            case xml_key
                {% for xml_key in column_config.keys() %}
                    when '{{ xml_key | replace("'", "''") }}' then {{ loop.index }}
                {% endfor %}
                else 10000
            end,
            xml_key
    {% endset %}

    {% if execute %}
        {% set query_result = run_query(discovery_query) %}
        {% set discovered_columns = query_result.rows %}
    {% else %}
        {% set discovered_columns = [] %}
    {% endif %}

    {% for discovered_column in discovered_columns %}
        {% set xml_key = discovered_column[0] %}
        {% set xml_kind = discovered_column[1] %}
        {% set value_types = discovered_column[2] %}
        {% set config = column_config.get(xml_key, {}) %}
        {% set column_name = config.get('alias', xml_key_to_column_name(xml_key)) %}
        {% set data_type = config.get('data_type') %}

        {% if data_type is none %}
            {% if value_types == 'BOOLEAN' %}
                {% set data_type = 'boolean' %}
            {% elif value_types == 'INTEGER' %}
                {% set data_type = 'integer' %}
            {% elif value_types in ['DECIMAL', 'DOUBLE', 'REAL'] %}
                {% set data_type = 'number' %}
            {% elif 'ARRAY' in value_types or 'OBJECT' in value_types %}
                {% set data_type = 'variant' %}
            {% else %}
                {% set data_type = 'string' %}
            {% endif %}
        {% endif %}

        {% if xml_kind == 'attribute' %}
            {% set value_expression = "get(" ~ xml_column ~ ", '" ~ xml_key ~ "')" %}
        {% else %}
            {% set value_expression = "get(xmlget(" ~ xml_column ~ ", '" ~ xml_key ~ "'), '$')" %}
        {% endif %}

        {% if data_type in ['date', 'timestamp', 'timestamp_ntz', 'timestamp_ltz', 'timestamp_tz'] %}
            try_to_{{ data_type }}({{ value_expression }}::string) as {{ column_name }}
        {% else %}
            {{ value_expression }}::{{ data_type }} as {{ column_name }}
        {% endif %}
        {% if not loop.last or passthrough_columns | length > 0 %},{% endif %}
    {% endfor %}

    {% for passthrough_column in passthrough_columns %}
        {{ passthrough_column }}{% if not loop.last %},{% endif %}
    {% endfor %}

{% endmacro %}
