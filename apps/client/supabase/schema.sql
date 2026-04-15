-- Nexo - schema base de clientes, vendas e gastos
-- Importante:
-- 1. Este schema usa politicas abertas para o papel anon porque ainda nao existe auth.
-- 2. Isso serve para desenvolvimento e validacao do produto.
-- 3. Antes de producao, substitua por politicas por usuario/workspace.

create table if not exists public.clients (
  id text primary key,
  name text not null,
  client_type text not null default 'pf' check (client_type in ('pf', 'pj')),
  legal_name text,
  document text,
  phone text,
  notes text,
  origin text,
  zip_code text,
  street text,
  street_number text,
  address_complement text,
  neighborhood text,
  city text,
  state_code text,
  country text not null default 'BR',
  status text not null default 'active',
  billing_type text not null default 'one_off',
  has_daniel_participation boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.sales (
  id text primary key,
  client_id text references public.clients(id) on delete set null,
  client_name text not null,
  service_name text not null,
  project_group text,
  service_stage text,
  gross_amount numeric(12, 2) not null default 0 check (gross_amount >= 0),
  platform text not null,
  payment_method text not null,
  installments integer not null default 1 check (installments > 0),
  sale_date timestamptz not null default timezone('utc', now()),
  expected_date timestamptz not null default timezone('utc', now()),
  received_date timestamptz,
  status text not null default 'pending',
  notes text,
  platform_fee numeric(12, 2) not null default 0 check (platform_fee >= 0),
  payment_fee numeric(12, 2) not null default 0 check (payment_fee >= 0),
  net_amount numeric(12, 2) not null default 0,
  origin text,
  has_daniel_participation boolean not null default false,
  daniel_percent numeric(5, 2) not null default 0 check (daniel_percent >= 0),
  daniel_value numeric(12, 2) not null default 0,
  owner_amount numeric(12, 2) not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.expenses (
  id text primary key,
  title text not null,
  category text not null,
  subcategory text,
  amount numeric(12, 2) not null default 0 check (amount >= 0),
  scope text not null default 'business',
  account_name text not null,
  expense_date timestamptz not null default timezone('utc', now()),
  recurrence text,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_clients_document on public.clients (document);
create index if not exists idx_sales_client_id_sale_date
  on public.sales (client_id, sale_date desc);
create index if not exists idx_expenses_expense_date
  on public.expenses (expense_date desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_clients_updated_at on public.clients;
create trigger set_clients_updated_at
before update on public.clients
for each row
execute function public.set_updated_at();

drop trigger if exists set_sales_updated_at on public.sales;
create trigger set_sales_updated_at
before update on public.sales
for each row
execute function public.set_updated_at();

drop trigger if exists set_expenses_updated_at on public.expenses;
create trigger set_expenses_updated_at
before update on public.expenses
for each row
execute function public.set_updated_at();

alter table public.clients enable row level security;
alter table public.sales enable row level security;
alter table public.expenses enable row level security;

drop policy if exists "nexo_clients_select_dev" on public.clients;
create policy "nexo_clients_select_dev"
on public.clients
for select
to anon, authenticated
using (true);

drop policy if exists "nexo_clients_insert_dev" on public.clients;
create policy "nexo_clients_insert_dev"
on public.clients
for insert
to anon, authenticated
with check (true);

drop policy if exists "nexo_clients_update_dev" on public.clients;
create policy "nexo_clients_update_dev"
on public.clients
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "nexo_sales_select_dev" on public.sales;
create policy "nexo_sales_select_dev"
on public.sales
for select
to anon, authenticated
using (true);

drop policy if exists "nexo_sales_insert_dev" on public.sales;
create policy "nexo_sales_insert_dev"
on public.sales
for insert
to anon, authenticated
with check (true);

drop policy if exists "nexo_sales_update_dev" on public.sales;
create policy "nexo_sales_update_dev"
on public.sales
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "nexo_expenses_select_dev" on public.expenses;
create policy "nexo_expenses_select_dev"
on public.expenses
for select
to anon, authenticated
using (true);

drop policy if exists "nexo_expenses_insert_dev" on public.expenses;
create policy "nexo_expenses_insert_dev"
on public.expenses
for insert
to anon, authenticated
with check (true);

drop policy if exists "nexo_expenses_update_dev" on public.expenses;
create policy "nexo_expenses_update_dev"
on public.expenses
for update
to anon, authenticated
using (true)
with check (true);
