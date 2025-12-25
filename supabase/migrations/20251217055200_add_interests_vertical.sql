-- 20251217055200_add_interests_vertical.sql
-- CANONICAL PATCH (rewritten via pipeline):
-- Fix: environments differ on schema for:
--   - specialty_types.vertical_group
--   - canonical_verticals primary key + column names (code vs vertical_code, etc.)
-- We introspect and generate INSERT/UPDATE dynamically to avoid drift and reset failures.

begin;

-- ------------------------------------------------------------
-- 1) Ensure the default specialty exists (FK target)
-- ------------------------------------------------------------
do $$
declare
  has_vertical_group boolean;
begin
  select exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name   = 'specialty_types'
      and column_name  = 'vertical_group'
  )
  into has_vertical_group;

  if has_vertical_group then
    execute $ins$
      insert into public.specialty_types (code, label, vertical_group)
      values ('INTERESTS_GENERAL', 'Interests (General)', 'INTERESTS')
      on conflict (code) do update
        set label = excluded.label,
            vertical_group = excluded.vertical_group
    $ins$;
  else
    execute $ins$
      insert into public.specialty_types (code, label)
      values ('INTERESTS_GENERAL', 'Interests (General)')
      on conflict (code) do update
        set label = excluded.label
    $ins$;
  end if;
end $$;

-- ------------------------------------------------------------
-- 2) Ensure the INTERESTS vertical exists in canonical_verticals
--    (schema-aware for PK + columns)
-- ------------------------------------------------------------
do $$
declare
  id_col text;
  name_col text;
  def_col text;

  exists_row boolean;

  sql_ins text;
  sql_upd text;
begin
  -- Identify the "id" column used to store the vertical code
  -- Prefer common variants in stable order.
  select c.column_name
  into id_col
  from information_schema.columns c
  where c.table_schema='public'
    and c.table_name='canonical_verticals'
    and c.column_name in ('code','vertical_code','vertical_id','slug')
  order by case c.column_name
    when 'code' then 1
    when 'vertical_code' then 2
    when 'vertical_id' then 3
    when 'slug' then 4
    else 999 end
  limit 1;

  if id_col is null then
    raise exception 'canonical_verticals: cannot find id column (expected code/vertical_code/vertical_id/slug)';
  end if;

  -- Identify display name column
  select c.column_name
  into name_col
  from information_schema.columns c
  where c.table_schema='public'
    and c.table_name='canonical_verticals'
    and c.column_name in ('name','label','title','display_name')
  order by case c.column_name
    when 'name' then 1
    when 'label' then 2
    when 'title' then 3
    when 'display_name' then 4
    else 999 end
  limit 1;

  if name_col is null then
    raise exception 'canonical_verticals: cannot find name column (expected name/label/title/display_name)';
  end if;

  -- Identify default specialty FK column
  select c.column_name
  into def_col
  from information_schema.columns c
  where c.table_schema='public'
    and c.table_name='canonical_verticals'
    and c.column_name in ('default_specialty','default_specialty_code','default_specialty_type','default_specialty_key')
  order by case c.column_name
    when 'default_specialty' then 1
    when 'default_specialty_code' then 2
    when 'default_specialty_type' then 3
    when 'default_specialty_key' then 4
    else 999 end
  limit 1;

  if def_col is null then
    raise exception 'canonical_verticals: cannot find default specialty column (expected default_specialty*)';
  end if;

  -- Does row already exist?
  execute format(
    'select exists (select 1 from public.canonical_verticals where %I = %L)',
    id_col, 'INTERESTS'
  ) into exists_row;

  if exists_row then
    sql_upd := format(
      'update public.canonical_verticals set %I = %L, %I = %L where %I = %L',
      name_col, 'Interests',
      def_col,  'INTERESTS_GENERAL',
      id_col,   'INTERESTS'
    );
    execute sql_upd;
  else
    sql_ins := format(
      'insert into public.canonical_verticals (%I, %I, %I) values (%L, %L, %L)',
      id_col, name_col, def_col,
      'INTERESTS', 'Interests', 'INTERESTS_GENERAL'
    );
    execute sql_ins;
  end if;
end $$;

-- ------------------------------------------------------------
-- 3) Ensure INTERESTS is wired into vertical_canonical_specialties
-- ------------------------------------------------------------
insert into public.vertical_canonical_specialties (vertical_code, specialty_code, is_default)
values ('INTERESTS', 'INTERESTS_GENERAL', true)
on conflict (vertical_code, specialty_code) do update
  set is_default = excluded.is_default;

commit;