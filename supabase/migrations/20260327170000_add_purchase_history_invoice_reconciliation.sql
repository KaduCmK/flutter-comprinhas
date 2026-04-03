alter table public.purchase_history_items
add column if not exists origin text not null default 'cart',
add column if not exists raw_unit_label text,
add column if not exists nota_fiscal_item_id uuid,
add column if not exists produto_id uuid,
add column if not exists recorded_unit_price numeric,
add column if not exists recorded_total_price numeric,
add column if not exists matching_status text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'purchase_history_items_origin_check'
  ) then
    alter table public.purchase_history_items
    add constraint purchase_history_items_origin_check
    check (origin in ('cart', 'invoice_extra'));
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'purchase_history_items_matching_status_check'
  ) then
    alter table public.purchase_history_items
    add constraint purchase_history_items_matching_status_check
    check (
      matching_status is null
      or matching_status in ('matched', 'manual', 'unmatched', 'invoice_extra')
    );
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'purchase_history_items_nota_fiscal_item_id_fkey'
  ) then
    alter table public.purchase_history_items
    add constraint purchase_history_items_nota_fiscal_item_id_fkey
    foreign key (nota_fiscal_item_id)
    references public.itens_nota_fiscal(id)
    on delete set null;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'purchase_history_items_produto_id_fkey'
  ) then
    alter table public.purchase_history_items
    add constraint purchase_history_items_produto_id_fkey
    foreign key (produto_id)
    references public.produtos(id)
    on delete set null;
  end if;
end $$;

create index if not exists purchase_history_items_nota_fiscal_item_id_idx
on public.purchase_history_items (nota_fiscal_item_id);

create index if not exists purchase_history_items_produto_id_idx
on public.purchase_history_items (produto_id);
