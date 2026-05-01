# Nexo

Aplicativo de gestao financeira pessoal e empresarial com foco em uso diario real, cache local e sincronizacao com Supabase.

## Estrutura

- `apps/api`: backend em FastAPI para regras financeiras, backup, sync inicial e futuras integracoes.
- `apps/client`: app Flutter com design system do Nexo, persistencia inicial e suporte a web e Windows.
- `docs`: arquitetura, integracoes e estrategia do produto.

## Principais pontos desta base

- Cliente Flutter com dashboard, clientes, vendas, gastos e detalhe de cliente.
- Persistencia via Supabase com cache local leve no app.
- Schema e migrations versionados em `apps/client/supabase/`.
- Configuracao local sensivel mantida fora do versionamento.
- Supabase local e usado apenas para desenvolvimento; o APK de producao deve apontar para Supabase Cloud.

## Documentacao

- [Arquitetura](docs/architecture.md)
- [Integracoes](docs/integrations.md)
- [Producao pessoal Supabase](docs/production-readiness.md)
- [Cliente Flutter](apps/client/README.md)

## Supabase local

O Supabase local roda somente no PC de desenvolvimento. Ele nao serve o APK fora da sua rede.

```powershell
npx supabase start
```

## Rodando o backend

```powershell
cd apps/api
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -e .[dev]
uvicorn app.main:app --reload
```

## Rodando o cliente

```powershell
cd apps/client
flutter pub get
flutter run -d chrome --dart-define-from-file=supabase/dart_define.local.json
```

## Producao pessoal

GitHub guarda codigo e migrations, nao guarda o banco. Para o celular funcionar em dados moveis, Wi-Fi fora de casa ou qualquer rede externa, crie um projeto no Supabase Cloud e gere o APK com o arquivo local `apps/client/supabase/dart_define.production.json`.

```powershell
npx supabase login
npx supabase link --project-ref SEU_PROJECT_REF
npx supabase db push
cd apps/client
flutter build apk --release --dart-define-from-file=supabase/dart_define.production.json
```

Nunca versione `service_role`, secret keys, `.env` real ou arquivos reais de `dart_define`.
