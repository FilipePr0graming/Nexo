-- Nexo - backend completo para operacao local Supabase.
-- Desenvolvimento: RLS aberto para anon/authenticated. Endurecer antes de producao.

create extension if not exists pgcrypto with schema extensions;
create extension if not exists unaccent with schema extensions;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.users (
  id text primary key default extensions.gen_random_uuid()::text,
  auth_user_id uuid references auth.users(id) on delete cascade,
  name text not null default '',
  email text,
  role text not null default 'owner' check (role in ('owner', 'admin', 'member')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.companies (
  id text primary key default extensions.gen_random_uuid()::text,
  owner_user_id text references public.users(id) on delete set null,
  name text not null,
  legal_name text,
  document text,
  phone text,
  email text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.clients (
  id text primary key,
  company_id text references public.companies(id) on delete set null,
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
  status text not null default 'active'
    check (status in ('lead', 'active', 'in_progress', 'paused', 'completed')),
  billing_type text not null default 'one_off'
    check (billing_type in ('one_off', 'monthly', 'annual')),
  has_daniel_participation boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.projects (
  id text primary key default extensions.gen_random_uuid()::text,
  client_id text references public.clients(id) on delete cascade,
  name text not null,
  stage text not null default 'briefing',
  status text not null default 'active'
    check (status in ('active', 'paused', 'completed', 'canceled')),
  budget_amount numeric(12, 2) not null default 0 check (budget_amount >= 0),
  due_date timestamptz,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.payments (
  id text primary key,
  company_id text references public.companies(id) on delete set null,
  client_id text references public.clients(id) on delete set null,
  project_id text references public.projects(id) on delete set null,
  client_name text not null,
  service_name text not null,
  project_group text,
  service_stage text,
  gross_amount numeric(12, 2) not null default 0 check (gross_amount >= 0),
  platform text not null default 'Pix direto',
  payment_method text not null default 'Pix',
  installments integer not null default 1 check (installments > 0),
  sale_date timestamptz not null default timezone('utc', now()),
  expected_date timestamptz not null default timezone('utc', now()),
  received_date timestamptz,
  status text not null default 'pending'
    check (status in ('pending', 'received', 'late', 'canceled', 'refunded')),
  notes text,
  platform_fee numeric(12, 2) not null default 0 check (platform_fee >= 0),
  payment_fee numeric(12, 2) not null default 0 check (payment_fee >= 0),
  net_amount numeric(12, 2) not null default 0,
  origin text,
  has_daniel_participation boolean not null default false,
  daniel_percent numeric(5, 2) not null default 0 check (daniel_percent >= 0),
  daniel_value numeric(12, 2) not null default 0 check (daniel_value >= 0),
  owner_amount numeric(12, 2) not null default 0,
  partner_debt_status text not null default 'none'
    check (partner_debt_status in ('none', 'open', 'partial', 'paid')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.expenses (
  id text primary key,
  company_id text references public.companies(id) on delete set null,
  title text not null,
  category text not null,
  subcategory text,
  amount numeric(12, 2) not null default 0 check (amount >= 0),
  scope text not null default 'business' check (scope in ('business', 'personal')),
  account_name text not null,
  expense_date timestamptz not null default timezone('utc', now()),
  recurrence text check (recurrence in ('monthly', 'annual')),
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.partners (
  id text primary key default extensions.gen_random_uuid()::text,
  name text not null unique,
  default_percent numeric(5, 2) not null default 0,
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.partner_payments (
  id text primary key default extensions.gen_random_uuid()::text,
  partner_id text not null references public.partners(id) on delete cascade,
  payment_id text references public.payments(id) on delete cascade,
  description text not null,
  amount numeric(12, 2) not null check (amount >= 0),
  due_date timestamptz not null,
  paid_at timestamptz,
  status text not null default 'open' check (status in ('open', 'paid', 'canceled')),
  source text not null default 'manual' check (source in ('manual', 'generated')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.subscriptions (
  id text primary key default extensions.gen_random_uuid()::text,
  client_id text references public.clients(id) on delete cascade,
  title text not null,
  amount numeric(12, 2) not null default 0 check (amount >= 0),
  recurrence text not null check (recurrence in ('monthly', 'annual')),
  next_due_date timestamptz not null,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.goals (
  id text primary key default extensions.gen_random_uuid()::text,
  title text not null,
  target_amount numeric(12, 2) not null check (target_amount >= 0),
  current_amount numeric(12, 2) not null default 0 check (current_amount >= 0),
  due_date timestamptz,
  status text not null default 'active' check (status in ('active', 'done', 'paused')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.reminders (
  id text primary key default extensions.gen_random_uuid()::text,
  title text not null,
  description text,
  due_date timestamptz not null,
  status text not null default 'open' check (status in ('open', 'done', 'canceled')),
  recurrence text check (recurrence in ('monthly', 'annual')),
  related_table text,
  related_id text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.notes (
  id text primary key default extensions.gen_random_uuid()::text,
  title text not null default '',
  body text not null default '',
  related_table text,
  related_id text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_clients_document on public.clients (document);
create index if not exists idx_projects_client_id on public.projects (client_id);
create index if not exists idx_payments_client_id_sale_date on public.payments (client_id, sale_date desc);
create index if not exists idx_expenses_expense_date on public.expenses (expense_date desc);
create index if not exists idx_partner_payments_status_due_date on public.partner_payments (status, due_date);
create index if not exists idx_reminders_status_due_date on public.reminders (status, due_date);

create or replace function public.apply_payment_financial_rules()
returns trigger
language plpgsql
as $$
declare
  normalized_method text := lower(unaccent(coalesce(new.payment_method, '')));
begin
  if normalized_method like '%pix%' then
    new.payment_fee := 0;
    new.expected_date := coalesce(new.expected_date, new.sale_date);
  elsif normalized_method like '%cartao%' or normalized_method like '%cart%' or normalized_method like '%card%' then
    new.payment_fee := round(new.gross_amount * 0.07, 2);
  end if;

  new.platform_fee := greatest(coalesce(new.platform_fee, 0), 0);
  new.payment_fee := greatest(coalesce(new.payment_fee, 0), 0);
  new.net_amount := round(new.gross_amount - new.platform_fee - new.payment_fee, 2);

  if new.has_daniel_participation then
    new.daniel_percent := case when new.daniel_percent <= 0 then 30 else new.daniel_percent end;
    new.daniel_value := round(greatest(new.net_amount, 0) * (new.daniel_percent / 100), 2);
    new.partner_debt_status := case when new.daniel_value > 0 then 'open' else 'none' end;
  else
    new.daniel_percent := 0;
    new.daniel_value := 0;
    new.partner_debt_status := 'none';
  end if;

  new.owner_amount := round(new.net_amount - new.daniel_value, 2);
  return new;
end;
$$;

create or replace function public.ensure_daniel_partner_debt()
returns trigger
language plpgsql
as $$
declare
  daniel_id text;
  first_amount numeric(12, 2);
  second_amount numeric(12, 2);
begin
  select id into daniel_id from public.partners where lower(name) = 'daniel';

  if daniel_id is null then
    insert into public.partners (name, default_percent, notes)
    values ('Daniel', 30, 'Socio com pagamento manual. Contrato base: 30% de R$ 5.500 = R$ 1.650.')
    returning id into daniel_id;
  end if;

  delete from public.partner_payments
  where payment_id = new.id and partner_id = daniel_id and source = 'generated' and status = 'open';

  if not new.has_daniel_participation or new.daniel_value <= 0 then
    return new;
  end if;

  first_amount := least(800, new.daniel_value);
  second_amount := round(new.daniel_value - first_amount, 2);

  if first_amount > 0 then
    insert into public.partner_payments
      (partner_id, payment_id, description, amount, due_date, status, source)
    values
      (daniel_id, new.id, 'Daniel - parcela inicial manual', first_amount, new.sale_date, 'open', 'generated');
  end if;

  if second_amount > 0 then
    insert into public.partner_payments
      (partner_id, payment_id, description, amount, due_date, status, source)
    values
      (daniel_id, new.id, 'Daniel - parcela final manual', second_amount, new.expected_date, 'open', 'generated');
  end if;

  return new;
end;
$$;

create or replace function public.ensure_recurring_client_reminder()
returns trigger
language plpgsql
as $$
declare
  next_date timestamptz;
begin
  if new.billing_type not in ('monthly', 'annual') then
    return new;
  end if;

  next_date := case
    when new.billing_type = 'monthly' then timezone('utc', now()) + interval '1 month'
    else timezone('utc', now()) + interval '1 year'
  end;

  insert into public.reminders
    (title, description, due_date, recurrence, related_table, related_id)
  values
    ('Renovar cliente ' || new.name, 'Gerado automaticamente pela recorrencia do cliente.', next_date, new.billing_type, 'clients', new.id)
  on conflict do nothing;

  return new;
end;
$$;

create or replace function public.ensure_recurring_expense_reminder()
returns trigger
language plpgsql
as $$
declare
  next_date timestamptz;
begin
  if new.recurrence is null then
    return new;
  end if;

  next_date := case
    when new.recurrence = 'monthly' then new.expense_date + interval '1 month'
    else new.expense_date + interval '1 year'
  end;

  insert into public.reminders
    (title, description, due_date, recurrence, related_table, related_id)
  values
    ('Pagar ' || new.title, 'Gerado automaticamente por gasto recorrente.', next_date, new.recurrence, 'expenses', new.id)
  on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists set_users_updated_at on public.users;
create trigger set_users_updated_at before update on public.users for each row execute function public.set_updated_at();
drop trigger if exists set_companies_updated_at on public.companies;
create trigger set_companies_updated_at before update on public.companies for each row execute function public.set_updated_at();
drop trigger if exists set_clients_updated_at on public.clients;
create trigger set_clients_updated_at before update on public.clients for each row execute function public.set_updated_at();
drop trigger if exists set_projects_updated_at on public.projects;
create trigger set_projects_updated_at before update on public.projects for each row execute function public.set_updated_at();
drop trigger if exists set_payments_updated_at on public.payments;
create trigger set_payments_updated_at before update on public.payments for each row execute function public.set_updated_at();
drop trigger if exists set_expenses_updated_at on public.expenses;
create trigger set_expenses_updated_at before update on public.expenses for each row execute function public.set_updated_at();
drop trigger if exists set_partners_updated_at on public.partners;
create trigger set_partners_updated_at before update on public.partners for each row execute function public.set_updated_at();
drop trigger if exists set_partner_payments_updated_at on public.partner_payments;
create trigger set_partner_payments_updated_at before update on public.partner_payments for each row execute function public.set_updated_at();
drop trigger if exists set_subscriptions_updated_at on public.subscriptions;
create trigger set_subscriptions_updated_at before update on public.subscriptions for each row execute function public.set_updated_at();
drop trigger if exists set_goals_updated_at on public.goals;
create trigger set_goals_updated_at before update on public.goals for each row execute function public.set_updated_at();
drop trigger if exists set_reminders_updated_at on public.reminders;
create trigger set_reminders_updated_at before update on public.reminders for each row execute function public.set_updated_at();
drop trigger if exists set_notes_updated_at on public.notes;
create trigger set_notes_updated_at before update on public.notes for each row execute function public.set_updated_at();

drop trigger if exists apply_payment_financial_rules on public.payments;
create trigger apply_payment_financial_rules before insert or update on public.payments
for each row execute function public.apply_payment_financial_rules();

drop trigger if exists ensure_daniel_partner_debt on public.payments;
create trigger ensure_daniel_partner_debt after insert or update on public.payments
for each row execute function public.ensure_daniel_partner_debt();

drop trigger if exists ensure_recurring_client_reminder on public.clients;
create trigger ensure_recurring_client_reminder after insert or update of billing_type on public.clients
for each row execute function public.ensure_recurring_client_reminder();

drop trigger if exists ensure_recurring_expense_reminder on public.expenses;
create trigger ensure_recurring_expense_reminder after insert or update of recurrence on public.expenses
for each row execute function public.ensure_recurring_expense_reminder();

insert into public.partners (name, default_percent, notes)
values ('Daniel', 30, 'Socio com pagamento manual. Contrato base: 30% de R$ 5.500 = R$ 1.650; parcelas R$ 800 no inicio e R$ 850 no final.')
on conflict (name) do update
set default_percent = excluded.default_percent,
    notes = excluded.notes;

insert into public.partner_payments (partner_id, description, amount, due_date, status, source)
select id, 'Daniel - contrato base parcela inicial', 800, timezone('utc', now()), 'open', 'manual'
from public.partners
where name = 'Daniel'
  and not exists (
    select 1 from public.partner_payments
    where description = 'Daniel - contrato base parcela inicial'
  );

insert into public.partner_payments (partner_id, description, amount, due_date, status, source)
select id, 'Daniel - contrato base parcela final', 850, timezone('utc', now()) + interval '30 days', 'open', 'manual'
from public.partners
where name = 'Daniel'
  and not exists (
    select 1 from public.partner_payments
    where description = 'Daniel - contrato base parcela final'
  );

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'users', 'companies', 'clients', 'projects', 'payments', 'expenses',
    'partners', 'partner_payments', 'subscriptions', 'goals', 'reminders', 'notes'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('drop policy if exists %I on public.%I', 'nexo_' || table_name || '_dev_all', table_name);
    execute format(
      'create policy %I on public.%I for all to anon, authenticated using (true) with check (true)',
      'nexo_' || table_name || '_dev_all',
      table_name
    );
  end loop;
end;
$$;
