# Nexo

Aplicativo de gestao financeira pessoal e empresarial com foco em uso diario real, arquitetura local-first e base preparada para sincronizacao com Supabase.

## Estrutura

- `apps/api`: backend em FastAPI para regras financeiras, backup, sync inicial e futuras integracoes.
- `apps/client`: app Flutter com design system do Nexo, persistencia inicial e suporte a web e Windows.
- `docs`: arquitetura, integracoes e estrategia do produto.

## Principais pontos desta base

- Cliente Flutter com dashboard, clientes, vendas, gastos e detalhe de cliente.
- Persistencia inicial via Supabase com cache local leve no app.
- Schema e migrations versionados em `apps/client/supabase/`.
- Configuracao local sensivel mantida fora do versionamento.

## Documentacao

- [Arquitetura](docs/architecture.md)
- [Integracoes](docs/integrations.md)
- [Cliente Flutter](apps/client/README.md)

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
