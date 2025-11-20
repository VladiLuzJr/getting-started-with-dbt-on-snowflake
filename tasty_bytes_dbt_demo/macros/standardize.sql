{% macro deduplicate_standard(source_model, unique_key) %}
  {# Reference the upstream model #}
  {% set relation = ref(source_model) %}
  {% set columns = adapter.get_columns_in_relation(relation) %}
  {% set preferred = ['updated_at', 'last_updated_at', 'modified_at', 'modified_ts', 'updated_ts'] %}
  {% set order_column = none %}
  {% for candidate in preferred %}
    {% if order_column is none %}
      {% for col in columns %}
        {% if col.name | lower == candidate %}
          {% set order_column = col.name %}
        {% endif %}
      {% endfor %}
    {% endif %}
  {% endfor %}

  select *
  from {{ relation }}
  qualify row_number() over (
    partition by {{ adapter.quote(unique_key) }}
    order by {% if order_column %} {{ adapter.quote(order_column) }} desc nulls last {% else %} {{ adapter.quote(unique_key) }} {% endif %}
  ) = 1
{% endmacro %}
