# Nexo Client

App Flutter do Nexo com design system proprio, persistencia em Supabase e cache local leve.

## O que esta pronto nesta etapa

- Integracao de `supabase_flutter`
- Estrutura limpa de `config`, `models`, `data sources`, `repositories` e `services`
- Persistencia real de `clientes`, `vendas` e `gastos`
- Cache local serializado para leitura rapida e fallback inicial
- Dashboard e listas ligadas a dados reais
- Login por e-mail/senha quando Supabase esta configurado

## Ambiente local

O Supabase local e usado somente no PC.

```powershell
npx supabase start
cd apps/client
flutter pub get
flutter run -d chrome --dart-define-from-file=supabase/dart_define.local.json
```

Crie `supabase/dart_define.local.json` a partir de [supabase/dart_define.local.example.json](./supabase/dart_define.local.example.json).

## Ambiente de producao pessoal

O APK fora do PC precisa usar Supabase Cloud.

1. Crie um projeto no painel do Supabase Cloud no plano gratis.
2. Copie `Project URL`.
3. Copie a chave publica `anon` ou `publishable`.
4. Crie localmente `supabase/dart_define.production.json` a partir de [supabase/dart_define.production.example.json](./supabase/dart_define.production.example.json).
5. Linke o projeto e aplique as migrations:

```powershell
npx supabase login
npx supabase link --project-ref SEU_PROJECT_REF
npx supabase db push
```

6. Crie seu usuario em Authentication no Supabase Cloud ou habilite cadastro conforme sua preferencia.

## Builds

```powershell
flutter build web --dart-define-from-file=supabase/dart_define.production.json
flutter build apk --release --dart-define-from-file=supabase/dart_define.production.json
```

## Seguranca

- O Flutter usa apenas `SUPABASE_URL` e chave publica `SUPABASE_ANON_KEY` ou `SUPABASE_PUBLISHABLE_KEY`.
- Nunca use `service_role` ou secret key no Flutter, web build, APK ou GitHub.
- RLS esta ativado nas tabelas e exige usuario autenticado.
- A permissao limitada para esposa ainda precisa de evolucao de schema/policies por perfil ou escopo.

Sem credenciais, o app ainda abre, mas funciona em modo local sem Supabase remoto.

## Rodar no Windows

```powershell
flutter run -d windows --dart-define-from-file=supabase/dart_define.local.json
```

Observacao importante:
- Plugins Flutter para Windows exigem suporte a symlink.
- Se aparecer a mensagem `Building with plugins requires symlink support`, ative o `Developer Mode` no Windows:

```powershell
start ms-settings:developers
```

## Estrutura principal

- `lib/core/config`: ambiente e bootstrap
- `lib/core/storage`: cache local
- `lib/features/clients`: modelos, persistencia e telas de clientes
- `lib/features/finance`: modelos, persistencia e fluxos de venda/gasto

## Validacao feita

- `flutter analyze`
- `flutter build web`
- `flutter run -d chrome --no-resident`

No ambiente em que implementei, `flutter build windows` parou por falta de suporte a symlink no Windows, o que precisa ser habilitado no sistema operacional.
