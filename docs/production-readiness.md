# NEXO production readiness

ID: NEXO-PROD-READINESS-001

## Estado detectado

- O app Flutter inicializa Supabase por `dart-define` em `apps/client/lib/core/config/app_environment.dart`.
- O arquivo local real detectado e ignorado pelo Git e `apps/client/supabase/dart_define.local.json`.
- Esse arquivo aponta para `http://127.0.0.1:54321`, entao o banco em uso no desenvolvimento atual e o Supabase local.
- Quando `SUPABASE_URL` e chave publica nao sao fornecidos, o app continua abrindo com cache local/offline.
- Nao foi encontrada `service_role` ou secret key versionada.

## Tabelas confirmadas

- `users`
- `companies`
- `clients`
- `projects`
- `payments`
- `expenses`
- `partners`
- `partner_payments`
- `subscriptions`
- `goals`
- `reminders`
- `notes`

## Configuracao

- Desenvolvimento local do app: `apps/client/supabase/dart_define.local.json`
- Exemplo local: `apps/client/supabase/dart_define.local.example.json`
- Exemplo producao: `apps/client/supabase/dart_define.production.example.json`
- Exemplos tambem existem em `supabase/` para referencia na raiz do repo.
- Arquivos reais ignorados: `.env`, `apps/client/supabase/dart_define.local.json`, `apps/client/supabase/dart_define.production.json`, `supabase/dart_define.local.json`, `supabase/dart_define.production.json`.

## Migrations

- Migrations versionadas na raiz para Supabase CLI: `supabase/migrations/`.
- Migrations espelhadas do client: `apps/client/supabase/migrations/`.
- A migration `20260501133000_harden_rls_authenticated_only.sql` remove a politica aberta para `anon` e exige `authenticated`.

## Riscos encontrados

- Antes desta preparacao, as politicas RLS permitiam `anon, authenticated using (true)`, o que e inadequado para Supabase Cloud.
- O app ainda nao tem modelo de permissao por area para a esposa. Com o schema atual, qualquer usuario autenticado no projeto acessa os mesmos dados.
- Para permissao limitada por Casa, Metas, Compras e Lembretes sera preciso evoluir schema/policies com dono, perfil ou escopo por tabela/registro.

## O que muda para o APK funcionar fora do PC

- Criar um projeto no Supabase Cloud.
- Aplicar migrations no banco Cloud.
- Criar usuario por e-mail/senha no Supabase Auth.
- Criar localmente `apps/client/supabase/dart_define.production.json` com Project URL e anon/publishable key.
- Gerar o APK com `--dart-define-from-file=supabase/dart_define.production.json`.

## Comandos

Desenvolvimento local:

```powershell
npx supabase start
cd apps/client
flutter run -d chrome --dart-define-from-file=supabase/dart_define.local.json
```

Producao Supabase Cloud:

```powershell
npx supabase login
npx supabase link --project-ref SEU_PROJECT_REF
npx supabase db push
```

Builds:

```powershell
cd apps/client
flutter build web --dart-define-from-file=supabase/dart_define.production.json
flutter build apk --release --dart-define-from-file=supabase/dart_define.production.json
```

## Seguranca Supabase

- Flutter usa apenas Project URL e chave publica `anon` ou `publishable`.
- `service_role` e secret keys nunca devem entrar no app Flutter, APK, web build ou GitHub.
- Chaves elevadas ficam apenas em backend seguro ou Edge Functions.
