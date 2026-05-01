-- Nexo - endurecimento minimo para producao pessoal.
-- Mantem o schema atual e exige login Supabase Auth para acessar dados.

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
    execute format('drop policy if exists %I on public.%I', 'nexo_' || table_name || '_authenticated_all', table_name);
    execute format(
      'create policy %I on public.%I for all to authenticated using (true) with check (true)',
      'nexo_' || table_name || '_authenticated_all',
      table_name
    );
  end loop;
end;
$$;
