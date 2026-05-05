import 'package:supabase_flutter/supabase_flutter.dart';

class NexoIntelligenceService {
  const NexoIntelligenceService(this._client);

  final SupabaseClient? _client;

  Future<IntelligenceResult> ask({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      return IntelligenceResult.fallback(type, payload);
    }

    try {
      final response = await client.functions.invoke(
        'nexo-intelligence',
        body: {
          'type': type,
          'payload': payload,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final result = data['result'];
        if (result is Map<String, dynamic>) {
          return IntelligenceResult(
            title: (result['title'] as String?) ?? 'Analise Nexo',
            summary: (result['summary'] as String?) ??
                (result['message'] as String?) ??
                'Analise gerada.',
            actions: (result['actions'] as List?)
                    ?.whereType<String>()
                    .toList(growable: false) ??
                const [],
            source: (data['source'] as String?) ?? 'groq',
          );
        }
      }
    } catch (_) {
      return IntelligenceResult.fallback(type, payload);
    }

    return IntelligenceResult.fallback(type, payload);
  }
}

class IntelligenceResult {
  const IntelligenceResult({
    required this.title,
    required this.summary,
    required this.actions,
    required this.source,
  });

  final String title;
  final String summary;
  final List<String> actions;
  final String source;

  factory IntelligenceResult.fallback(
    String type,
    Map<String, dynamic> payload,
  ) {
    final free = (payload['dinheiroLivreHoje'] as num?)?.toDouble() ?? 0;
    final summary = switch (type) {
      'spending_advice' => free > 300
          ? 'Compra pequena pode caber, mas confira contas proximas antes.'
          : 'Melhor segurar compras agora e priorizar contas proximas.',
      'client_collection_message' =>
        'Oi, tudo bem? Passando para lembrar da cobranca pendente. Pode me dar uma previsao de pagamento?',
      _ =>
        'Confira dinheiro livre, contas proximas e cobrancas antes de gastar hoje.',
    };

    return IntelligenceResult(
      title: 'Analise Nexo',
      summary: summary,
      actions: const [
        'Separar contas proximas',
        'Cobrar clientes pendentes',
        'Registrar gasto novo',
      ],
      source: 'fallback',
    );
  }
}
