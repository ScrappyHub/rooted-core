begin;

-- Canonical verticals table columns you showed:
-- (vertical_code, label, description, sort_order, default_specialty)

insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (
  values
    -- Commerce-family expansions (future lanes)
    ('DELIVERY_LOGISTICS_MARKET', 'Delivery Marketplace', 'Future: delivery logistics marketplace (separate lifeform).', 12100, 'ROOTED_PLATFORM_CANONICAL'),
    ('ETHICAL_FOOD_MARKET',       'Ethical Food Market',  'Future: verified ethical sourcing market (separate lifeform).', 12110, 'ROOTED_PLATFORM_CANONICAL'),

    -- Gaming
    ('ROOTED_GAMING',             'Rooted Gaming',        'Gaming identity + approved games + save states + strict privacy.', 13000, 'ROOTED_PLATFORM_CANONICAL')
) as v(vertical_code, label, description, sort_order, default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

commit;