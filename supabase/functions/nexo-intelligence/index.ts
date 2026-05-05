type RequestType =
  | "daily_summary"
  | "payment_priority"
  | "client_collection_message"
  | "note_to_reminder"
  | "spending_advice";

type IntelligenceRequest = {
  type?: RequestType;
  payload?: Record<string, unknown>;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authorization = request.headers.get("Authorization") ?? "";
    const user = await validateUser(authorization);
    if (!user) {
      return json({ error: "unauthorized" }, 401);
    }

    const input = (await request.json()) as IntelligenceRequest;
    const type = input.type;
    if (!type || !isAllowedType(type)) {
      return json({ error: "invalid_type" }, 400);
    }

    const payload = sanitizePayload(input.payload ?? {});
    const fallback = localFallback(type, payload);
    const groqKey = Deno.env.get("GROQ_API_KEY");
    const model = Deno.env.get("GROQ_MODEL") ?? "llama-3.3-70b-versatile";
    if (!groqKey) {
      return json({ ...fallback, source: "fallback" });
    }

    const groq = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${groqKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0.25,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content:
              "Voce e a inteligencia financeira do app NEXO. Responda em JSON compacto, em portugues do Brasil, sem expor dados sensiveis. Seja conservador com dinheiro.",
          },
          {
            role: "user",
            content: JSON.stringify({ type, payload }),
          },
        ],
      }),
    });

    if (!groq.ok) {
      return json({
        ...fallback,
        source: "fallback",
        warning: "groq_unavailable",
      });
    }

    const data = await groq.json();
    const content =
      data?.choices?.[0]?.message?.content ?? JSON.stringify(fallback);
    return json({
      type,
      model,
      source: "groq",
      result: safeJson(content, fallback.result),
    });
  } catch (_) {
    return json({ error: "internal_error", ...localFallback("daily_summary", {}) }, 500);
  }
});

async function validateUser(authorization: string) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !anonKey || !authorization.startsWith("Bearer ")) {
    return null;
  }

  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      Authorization: authorization,
      apikey: anonKey,
    },
  });
  if (!response.ok) {
    return null;
  }
  return await response.json();
}

function isAllowedType(type: string): type is RequestType {
  return [
    "daily_summary",
    "payment_priority",
    "client_collection_message",
    "note_to_reminder",
    "spending_advice",
  ].includes(type);
}

function sanitizePayload(payload: Record<string, unknown>) {
  const text = JSON.stringify(payload);
  if (text.length <= 6000) {
    return payload;
  }
  return JSON.parse(text.slice(0, 6000));
}

function localFallback(type: RequestType, payload: Record<string, unknown>) {
  const money = payload["dinheiroLivreHoje"] ?? payload["amount"] ?? 0;
  const summary =
    type === "client_collection_message"
      ? "Oi, tudo bem? Passando para lembrar da cobranca pendente. Pode me dar uma previsao de pagamento?"
      : type === "spending_advice"
        ? Number(money) > 300
          ? "Compra pequena cabe melhor que compra grande. Confira contas proximas antes de pagar."
          : "Melhor segurar a compra agora e priorizar contas proximas."
        : "Confira entradas, contas proximas e lembretes antes de gastar hoje.";

  return {
    type,
    source: "fallback",
    result: {
      title: "Analise Nexo",
      summary,
      actions: [
        "Separar contas proximas",
        "Cobrar clientes pendentes",
        "Registrar qualquer gasto novo",
      ],
    },
  };
}

function safeJson(content: string, fallback: unknown) {
  try {
    return JSON.parse(content);
  } catch (_) {
    return { title: "Analise Nexo", summary: content, fallback };
  }
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
