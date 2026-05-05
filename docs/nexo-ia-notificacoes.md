# NEXO IA e notificacoes

## Groq

A integracao de IA fica fora do APK:

- Flutter chama a Supabase Edge Function `nexo-intelligence`.
- A Edge Function valida o JWT do usuario no Supabase.
- A Edge Function chama a API da Groq usando `GROQ_API_KEY` do ambiente seguro.
- O app recebe JSON estruturado e usa fallback local quando a funcao ou a Groq falham.

Modelo padrao: `llama-3.3-70b-versatile`.

Variaveis esperadas na Supabase:

```bash
GROQ_API_KEY
GROQ_MODEL=llama-3.3-70b-versatile
```

Comandos de operacao:

```bash
npx supabase functions deploy nexo-intelligence
npx supabase secrets set GROQ_API_KEY=<valor-local>
npx supabase secrets set GROQ_MODEL=llama-3.3-70b-versatile
```

Nunca coloque `GROQ_API_KEY` em `dart-define`, Flutter, APK ou arquivos versionados.

## Notificacoes

Android:

- O app usa `flutter_local_notifications`.
- O canal local e `nexo_reminders`.
- A permissao `POST_NOTIFICATIONS` esta no AndroidManifest.
- Ao criar, editar, concluir ou excluir lembretes, o agendamento local e atualizado.
- Notas com `reminder_at` tambem criam lembrete e geram notificacao local no horario.

Web/computador:

- O alerta aparece dentro do app pela central de lembretes na tela Hoje e nas telas finais.
- Notificacao push web fora do app aberto exigiria Service Worker/FCM ou provedor equivalente. Isso nao foi acoplado agora para nao criar dependencia externa nem quebrar o Supabase Cloud existente.
