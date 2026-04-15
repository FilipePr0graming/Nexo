# Nexo Client

App Flutter do Nexo com design system proprio, persistencia inicial em Supabase e cache local leve para preparar a base local-first.

## O que esta pronto nesta etapa

- Integracao de `supabase_flutter`
- Estrutura limpa de `config`, `models`, `data sources`, `repositories` e `services`
- Persistencia real de `clientes`, `vendas` e `gastos`
- Cache local serializado para leitura rapida e fallback inicial
- Dashboard e listas ligadas a dados reais

## 1. Criar projeto no Supabase

1. Crie um projeto no painel do Supabase.
2. Copie a `Project URL`.
3. Copie a `anon public key`.

## 2. Criar tabelas

1. Abra o SQL Editor do Supabase.
2. Execute o arquivo [supabase/schema.sql](./supabase/schema.sql).

Observacao:
- O schema desta etapa usa politicas abertas para `anon` porque o app ainda nao tem autenticacao.
- Isso e intencional para desenvolvimento e deve ser endurecido antes de producao.

## 3. Configurar credenciais no Flutter

1. Copie [supabase/dart_define.example.json](./supabase/dart_define.example.json) para um arquivo local, por exemplo `supabase/dart_define.local.json`.
2. Preencha com sua `SUPABASE_URL` e sua `SUPABASE_ANON_KEY`.

## 4. Instalar dependencias

```powershell
flutter pub get
```

## 5. Rodar no Chrome

```powershell
flutter run -d chrome --dart-define-from-file=supabase/dart_define.local.json
```

Sem as credenciais, o app ainda abre, mas funciona em modo local sem Supabase remoto.

## 6. Rodar no Windows

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
