{# By default dbt prefixes custom schemas with the target schema
   (e.g. dbt_dev_analytics). This override keeps schema names clean
   in dev, matching the schema set per-folder in dbt_project.yml. #}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
