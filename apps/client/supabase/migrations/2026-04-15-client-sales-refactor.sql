-- Nexo - migracao da modelagem de clientes e vendas
-- Objetivo:
-- 1. Cliente vira identidade + documento + endereco
-- 2. Venda passa a carregar servico, grupo e etapa
-- 3. O cliente deixa de ficar preso a um unico servico
--
-- Plano recomendado:
-- Fase 1. Executar este script para adicionar colunas novas e copiar o que for seguro.
-- Fase 2. Atualizar o app Flutter para a nova versao.
-- Fase 3. Validar alguns clientes e vendas reais.
-- Fase 4. So depois remover colunas antigas do cliente.

begin;

alter table public.clients
  add column if not exists client_type text not null default 'pf',
  add column if not exists legal_name text,
  add column if not exists document text,
  add column if not exists zip_code text,
  add column if not exists street text,
  add column if not exists street_number text,
  add column if not exists address_complement text,
  add column if not exists neighborhood text,
  add column if not exists city text,
  add column if not exists state_code text,
  add column if not exists country text not null default 'BR';

alter table public.clients
  drop constraint if exists clients_client_type_check;

alter table public.clients
  add constraint clients_client_type_check
  check (client_type in ('pf', 'pj'));

alter table public.sales
  add column if not exists project_group text,
  add column if not exists service_stage text;

-- Copia o que hoje esta no cliente mas na pratica pertence a venda
update public.sales as s
set
  project_group = coalesce(s.project_group, c.project_group),
  service_stage = coalesce(s.service_stage, c.current_stage)
from public.clients as c
where s.client_id = c.id;

-- Se houver documento ja salvo manualmente no futuro, o tipo pode ser inferido.
update public.clients
set client_type = case
  when regexp_replace(coalesce(document, ''), '\D', '', 'g') ~ '^\d{14}$' then 'pj'
  when regexp_replace(coalesce(document, ''), '\D', '', 'g') ~ '^\d{11}$' then 'pf'
  else client_type
end;

create index if not exists idx_clients_document on public.clients (document);
create index if not exists idx_sales_client_id_sale_date
  on public.sales (client_id, sale_date desc);

commit;

-- Validacao manual recomendada antes de remover colunas antigas:
-- select id, name, sales_platform, service_name, project_group, current_stage from public.clients;
-- select id, client_name, service_name, project_group, service_stage from public.sales order by sale_date desc;
--
-- Remocao final das colunas antigas do cliente:
-- alter table public.clients drop column if exists sales_platform;
-- alter table public.clients drop column if exists service_name;
-- alter table public.clients drop column if exists project_group;
-- alter table public.clients drop column if exists current_stage;
--
-- Observacao:
-- O antigo clients.service_name nao deve ser transformado automaticamente em venda,
-- porque um cliente pode ter varias compras e nao existe garantia de qual venda esse
-- servico descrevia. Se houver clientes antigos com esse campo preenchido e sem vendas
-- registradas, revise manualmente antes de apagar a coluna.
