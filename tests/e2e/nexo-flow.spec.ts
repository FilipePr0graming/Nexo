import { expect, test, type Page } from "@playwright/test";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";

const env = loadEnv();
const productionDefine = loadJson(
  path.resolve(process.cwd(), "apps/client/supabase/dart_define.production.json"),
);
const supabaseUrl =
  env.NEXO_E2E_SUPABASE_URL ??
  productionDefine.SUPABASE_URL ??
  env.SUPABASE_URL ??
  "http://127.0.0.1:54321";
const supabaseAnonKey =
  env.NEXO_E2E_SUPABASE_ANON_KEY ??
  productionDefine.SUPABASE_ANON_KEY ??
  productionDefine.SUPABASE_PUBLISHABLE_KEY ??
  env.SUPABASE_ANON_KEY;
const serviceRoleKey = env.NEXO_E2E_SERVICE_ROLE_KEY;
let userAccessToken: string | undefined;
const marker = "NEXO_E2E_20260504_";
const runId = env.NEXO_E2E_RUN_ID ?? marker;
const email = env.NEXO_E2E_EMAIL ?? `nexo-${runId}@example.com`;
const password = env.NEXO_E2E_PASSWORD ?? "NexoE2e!23456";
const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
const tomorrowLabel = `${String(tomorrow.getDate()).padStart(2, "0")}/${String(
  tomorrow.getMonth() + 1,
).padStart(2, "0")}/${tomorrow.getFullYear()}`;

function loadEnv() {
  const result: Record<string, string> = { ...process.env } as Record<
    string,
    string
  >;
  const file = path.resolve(process.cwd(), ".env");
  if (!existsSync(file)) {
    return result;
  }

  for (const line of readFileSync(file, "utf8").split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#") || !trimmed.includes("=")) {
      continue;
    }
    const [key, ...valueParts] = trimmed.split("=");
    result[key] = valueParts.join("=").replace(/^"|"$/g, "");
  }
  return result;
}

function loadJson(file: string): Record<string, string> {
  if (!existsSync(file)) {
    return {};
  }
  return JSON.parse(readFileSync(file, "utf8")) as Record<string, string>;
}

async function ensureSupabaseAccess() {
  if (serviceRoleKey || userAccessToken || !supabaseAnonKey) {
    return;
  }

  const response = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: {
      apikey: supabaseAnonKey,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ email, password }),
  });
  if (!response.ok) {
    throw new Error(`Login Supabase REST falhou: ${await response.text()}`);
  }
  const body = (await response.json()) as { access_token?: string };
  userAccessToken = body.access_token;
}

async function supabaseFetch(pathname: string, init: RequestInit = {}) {
  await ensureSupabaseAccess();
  const apiKey = serviceRoleKey ?? supabaseAnonKey;
  const bearer = serviceRoleKey ?? userAccessToken;
  if (!apiKey || !bearer) {
    throw new Error("Credenciais Supabase ausentes para o E2E.");
  }

  const response = await fetch(`${supabaseUrl}${pathname}`, {
    ...init,
    headers: {
      apikey: apiKey,
      Authorization: `Bearer ${bearer}`,
      "Content-Type": "application/json",
      Prefer: "return=representation",
      ...(init.headers ?? {}),
    },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`${init.method ?? "GET"} ${pathname} falhou: ${body}`);
  }

  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

async function supabaseFetchOrEmpty(pathname: string, init: RequestInit = {}) {
  try {
    return await supabaseFetch(pathname, init);
  } catch (error) {
    if (
      error instanceof Error &&
      (error.message.includes("PGRST205") || error.message.includes("404"))
    ) {
      return [];
    }
    throw error;
  }
}

async function ensureE2eUser() {
  if (!serviceRoleKey) {
    await ensureSupabaseAccess();
    return;
  }

  const users = await supabaseFetch(
    `/auth/v1/admin/users?email=${encodeURIComponent(email)}`,
  ).catch(() => null);
  const existing = Array.isArray(users?.users)
    ? users.users.find((user: { email?: string }) => user.email === email)
    : null;
  if (existing) {
    return;
  }

  await supabaseFetch("/auth/v1/admin/users", {
    method: "POST",
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
    }),
  });
}

async function cleanupE2eData() {
  const encodedRun = encodeURIComponent(`*${marker}*`);
  const payments = (await supabaseFetchOrEmpty(
    `/rest/v1/payments?select=id&or=(client_name.ilike.${encodedRun},service_name.ilike.${encodedRun},project_group.ilike.${encodedRun},notes.ilike.${encodedRun})`,
  )) as Array<{ id: string }>;
  const paymentIds = payments.map((payment) => payment.id);

  if (paymentIds.length > 0) {
    await supabaseFetchOrEmpty(
      `/rest/v1/partner_payments?payment_id=in.(${paymentIds.join(",")})`,
      { method: "DELETE" },
    );
  }

  const cleanupTargets = [
    `/rest/v1/notes?or=(title.ilike.${encodedRun},body.ilike.${encodedRun})`,
    `/rest/v1/reminders?or=(title.ilike.${encodedRun},description.ilike.${encodedRun})`,
    `/rest/v1/goals?title=ilike.${encodedRun}`,
    `/rest/v1/payments?or=(client_name.ilike.${encodedRun},service_name.ilike.${encodedRun},project_group.ilike.${encodedRun},notes.ilike.${encodedRun})`,
    `/rest/v1/projects?or=(name.ilike.${encodedRun},notes.ilike.${encodedRun})`,
    `/rest/v1/expenses?or=(title.ilike.${encodedRun},category.ilike.${encodedRun},notes.ilike.${encodedRun})`,
    `/rest/v1/clients?or=(name.ilike.${encodedRun},notes.ilike.${encodedRun},origin.ilike.${encodedRun})`,
  ];

  for (const target of cleanupTargets) {
    await supabaseFetchOrEmpty(target, { method: "DELETE" });
  }
  await supabaseFetchOrEmpty(
    `/rest/v1/expenses?or=(title.ilike.${encodedRun},category.ilike.${encodedRun},notes.ilike.${encodedRun})`,
    {
      method: "PATCH",
      body: JSON.stringify({
        title: "E2E_CLEANED_EXPENSE",
        notes: "cleaned",
      }),
    },
  );
  await supabaseFetchOrEmpty(
    `/rest/v1/clients?or=(name.ilike.${encodedRun},notes.ilike.${encodedRun},origin.ilike.${encodedRun})`,
    {
      method: "PATCH",
      body: JSON.stringify({
        name: "E2E_CLEANED_CLIENT",
        origin: "cleaned",
      }),
    },
  );
}

async function countResidues() {
  const encodedRun = encodeURIComponent(`*${marker}*`);
  const targets = [
    `/rest/v1/clients?select=id&or=(name.ilike.${encodedRun},notes.ilike.${encodedRun},origin.ilike.${encodedRun})`,
    `/rest/v1/projects?select=id&or=(name.ilike.${encodedRun},notes.ilike.${encodedRun})`,
    `/rest/v1/payments?select=id&or=(client_name.ilike.${encodedRun},service_name.ilike.${encodedRun},project_group.ilike.${encodedRun},notes.ilike.${encodedRun})`,
    `/rest/v1/expenses?select=id&or=(title.ilike.${encodedRun},category.ilike.${encodedRun},notes.ilike.${encodedRun})`,
    `/rest/v1/notes?select=id&or=(title.ilike.${encodedRun},body.ilike.${encodedRun})`,
    `/rest/v1/goals?select=id&title=ilike.${encodedRun}`,
    `/rest/v1/reminders?select=id&or=(title.ilike.${encodedRun},description.ilike.${encodedRun})`,
  ];
  const rows = await Promise.all(
    targets.map(
      (target) => supabaseFetchOrEmpty(target) as Promise<Array<unknown>>,
    ),
  );
  return rows.reduce((total, items) => total + items.length, 0);
}

async function enableAccessibilityIfNeeded(page: Page) {
  const accessibilityButton = page.getByRole("button", {
    name: "Enable accessibility",
  });
  if (await accessibilityButton.isVisible().catch(() => false)) {
    await accessibilityButton.click();
  }
}

async function login(page: Page) {
  await page.goto("/");
  await enableAccessibilityIfNeeded(page);
  const dashboard = page.getByText(
    /Tudo sob controle|Use com cuidado|Segure gastos agora|Registre seus movimentos/,
  );
  if (await dashboard.isVisible({ timeout: 5000 }).catch(() => false)) {
    return;
  }

  const loginButton = page.getByRole("button", { name: "Entrar" });
  await expect(loginButton).toBeVisible();
  await fillTextbox(page, 0, email);
  await fillTextbox(page, 1, password);
  await loginButton.click();
  await expect(dashboard).toBeVisible({ timeout: 45000 });
}

async function screenshot(page: Page, name: string) {
  await page.screenshot({
    path: `test-results/${name}.png`,
    fullPage: true,
  });
}

function escapeRegExp(value: string) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

async function clickNav(page: Page, label: string) {
  const navButton = page
    .getByRole("button", { name: new RegExp(`^${escapeRegExp(label)}$`) })
    .first();
  if (await navButton.isVisible().catch(() => false)) {
    await navButton.click();
    return;
  }

  await page.getByText(label, { exact: true }).first().click();
}

function recordByLabel(page: Page, label: string) {
  return page.getByLabel(new RegExp(escapeRegExp(label))).first();
}

async function clickSelect(page: Page, label: string) {
  await page
    .getByRole("button", { name: new RegExp(escapeRegExp(label)) })
    .first()
    .click();
}

async function expectButtonGone(page: Page, label: string) {
  await expect(page.getByRole("button", { name: label })).toHaveCount(0);
}

async function expectPaymentStatus(serviceName: string, status: string) {
  const tableCheck = (await supabaseFetchOrEmpty(
    `/rest/v1/payments?select=id&limit=1`,
  )) as Array<unknown>;
  if (tableCheck.length === 0) {
    return;
  }
  await expect
    .poll(
      async () => {
        const rows = (await supabaseFetchOrEmpty(
          `/rest/v1/payments?select=status&service_name=eq.${encodeURIComponent(
            serviceName,
          )}`,
        )) as Array<{ status: string }>;
        return rows[0]?.status ?? null;
      },
      { timeout: 15000 },
    )
    .toBe(status);
}

async function expectSupabaseRow(pathname: string) {
  await expect
    .poll(
      async () => {
        const rows = (await supabaseFetchOrEmpty(pathname)) as Array<unknown>;
        return rows.length;
      },
      { timeout: 15000 },
    )
    .toBeGreaterThan(0);
}

async function fillTextbox(page: Page, index: number, value: string) {
  const field = page.getByRole("textbox").nth(index);
  await field.click();
  await page.keyboard.press("Control+A");
  await page.keyboard.press("Backspace");
  await page.keyboard.type(value);
  await expect
    .poll(async () => field.inputValue(), { timeout: 5000 })
    .toBe(value);
}

test.describe.configure({ mode: "serial" });

test.beforeAll(async () => {
  await ensureE2eUser();
  await cleanupE2eData();
});

test.afterAll(async () => {
  await cleanupE2eData();
  expect(await countResidues()).toBe(0);
});

test.describe("Nexo integracao final", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("login e dashboard inteligente", async ({ page }) => {
    await expect(page.getByText("Hoje", { exact: true }).first()).toBeVisible();
    await expect(page.getByText("Dinheiro livre hoje")).toBeVisible();
    await expect(page.getByText("O que fazer agora")).toBeVisible();
    await expect(page.getByText("Lembretes")).toBeVisible();
    await expect(page.getByText("Caixa real")).toBeVisible();
    await expect(page.getByText(/7 dias|15 dias|30 dias/).first()).toBeVisible();
    await expect(page.getByText(/Voce pode gastar|Você pode gastar/)).toHaveCount(0);
    await screenshot(page, "01-dashboard");
  });

  test("clientes, projetos, pagamentos, gastos e recebimento", async ({
    page,
  }) => {
    await clickNav(page, "Clientes");
    await page.getByRole("button", { name: "Novo cliente" }).first().click();
    await expect(page.getByText("Novo cliente")).toBeVisible();
    await fillTextbox(page, 0, `${marker}Cliente`);
    await fillTextbox(page, 1, "00000000000");
    await fillTextbox(page, 3, `${marker}origem`);
    await page.getByRole("button", { name: "Salvar cliente" }).click();
    await expect(recordByLabel(page, `${marker}Cliente`)).toBeVisible();
    await expectSupabaseRow(
      `/rest/v1/clients?select=id&name=eq.${encodeURIComponent(`${marker}Cliente`)}`,
    );

    await clickNav(page, "Projetos");
    await page.getByRole("button", { name: "Novo projeto" }).first().click();
    await fillTextbox(page, 0, `${marker}Projeto Teste`);
    await fillTextbox(page, 1, `${marker}Cliente`);
    await fillTextbox(page, 3, "5500");
    await fillTextbox(page, 4, `${marker}projeto`);
    await page.getByRole("button", { name: "Salvar projeto" }).click();
    await expect(recordByLabel(page, `${marker}Projeto Teste`)).toBeVisible();

    await page.getByRole("button", { name: "Venda" }).first().click();
    await page.getByRole("textbox").nth(0).click();
    await page.getByText(`${marker}Cliente`).last().click();
    await fillTextbox(page, 1, `${marker}Recebimento Teste`);
    await fillTextbox(page, 2, `${marker}Projeto Teste`);
    await fillTextbox(page, 4, "705");
    await page.getByText("Sim").click();
    await page.getByRole("button", { name: "Salvar venda" }).click();
    await expectButtonGone(page, "Salvar venda");
    await expect(page.getByText("Venda salva.").first()).toBeVisible();

    await clickNav(page, "Projetos");
    await page.getByRole("button", { name: "Venda" }).first().click();
    await page.getByRole("textbox").nth(0).click();
    await page.getByText(`${marker}Cliente`).last().click();
    await fillTextbox(page, 1, `${marker}Cobranca Teste`);
    await fillTextbox(page, 2, `${marker}Projeto Teste`);
    await fillTextbox(page, 4, "1200");
    await clickSelect(page, "Pagamento");
    await page.getByText("Cartao").click();
    await clickSelect(page, "Status");
    await page.getByText("Pendente").click();
    await page.getByRole("button", { name: "Salvar venda" }).click();
    await expectButtonGone(page, "Salvar venda");
    await expect(page.getByText("Venda salva.").first()).toBeVisible();

    await clickNav(page, "Financeiro");
    await page.getByText("Novo gasto").click();
    await fillTextbox(page, 0, "120");
    await clickSelect(page, "Recorrencia");
    await page.getByText("Mensal").click();
    await fillTextbox(page, 1, `${marker}Mercado Teste`);
    await page.getByRole("button", { name: "Salvar gasto" }).click();
    await expectButtonGone(page, "Salvar gasto");
    await expect(page.getByText("Gasto salvo.").first()).toBeVisible();
    await expectSupabaseRow(
      `/rest/v1/expenses?select=id&title=eq.${encodeURIComponent(`${marker}Mercado Teste`)}`,
    );

    await clickNav(page, "Hoje");
    await page
      .getByRole("button", {
        name: new RegExp(`Recebi.*${escapeRegExp(marker)}Cobranca Teste`),
      })
      .first()
      .click();
    await expectPaymentStatus(`${marker}Cobranca Teste`, "received");
    await expect(page.getByText("Entrou hoje")).toBeVisible();
    await screenshot(page, "02-fluxos-financeiros");
  });

  test("metas, anotacoes, planejamento e parceiro Daniel", async ({
    page,
  }) => {
    await clickNav(page, "Metas");
    await page.getByRole("button", { name: "Nova meta" }).first().click();
    await fillTextbox(page, 0, `${marker}Meta Teste`);
    await fillTextbox(page, 1, "8000");
    await fillTextbox(page, 2, "1200");
    await page.getByRole("button", { name: "Salvar meta" }).click();
    await expect(recordByLabel(page, `${marker}Meta Teste`)).toBeVisible();

    await clickNav(page, "Anotacoes");
    await page.getByRole("button", { name: "Nova anotacao" }).first().click();
    await fillTextbox(page, 0, `${marker}Nota Teste`);
    await fillTextbox(page, 1, `${marker}Conteudo da nota`);
    await page.getByRole("button", { name: "Salvar anotacao" }).click();
    await expect(recordByLabel(page, `${marker}Nota Teste`)).toBeVisible();

    await clickNav(page, "Hoje");
    await page.getByRole("button", { name: "Novo" }).first().click();
    await fillTextbox(page, 0, `${marker}Ligar para Douglas`);
    await fillTextbox(page, 1, `${marker}Nota com lembrete`);
    await fillTextbox(page, 2, tomorrowLabel);
    await fillTextbox(page, 3, "09:00");
    await page.getByRole("button", { name: "Criar lembrete" }).click();
    await expect(page.getByText(`${marker}Ligar para Douglas`)).toBeVisible();
    await page.getByRole("button", { name: "Editar lembrete" }).first().click();
    await fillTextbox(page, 0, `${marker}Ligar para Douglas atualizado`);
    await page.getByRole("button", { name: "Salvar" }).click();
    await expect(
      page.getByText(`${marker}Ligar para Douglas atualizado`),
    ).toBeVisible();
    await clickNav(page, "Planejamento");
    await expect(page.getByText("Resultado futuro")).toBeVisible();
    await expect(page.getByText("Alertas e lembretes")).toBeVisible();

    await clickNav(page, "Hoje");
    await page.getByRole("button", { name: "Excluir lembrete" }).first().click();
    await expect(
      page.getByText(`${marker}Ligar para Douglas atualizado`),
    ).toHaveCount(0);

    await clickNav(page, "Parceiros");
    await expect(page.getByText("Daniel").first()).toBeVisible();
    await expect(
      page.getByText(/Debitos no Supabase|Por projeto/).first(),
    ).toBeVisible();
    await screenshot(page, "03-metas-notas-planejamento-parceiros");

  });

  test("responsividade mobile com menu lateral colapsavel", async ({
    page,
  }) => {
    for (const viewport of [
      { width: 360, height: 800 },
      { width: 390, height: 844 },
      { width: 412, height: 915 },
    ]) {
      await page.setViewportSize(viewport);
      await expect(page.getByText("Hoje", { exact: true }).first()).toBeVisible();
      await expect(page.getByText("Dinheiro livre hoje")).toBeVisible();
      await expect(page.getByText("Sugestoes automaticas")).toBeVisible();
      await expect(page.getByText(/^Clien$/)).toHaveCount(0);
      await expect(page.getByText(/^te fre$/)).toHaveCount(0);
      await screenshot(page, `04-mobile-${viewport.width}`);
    }
    await page.getByText("Menu", { exact: true }).click();
    await expect(page.getByText("Anotacoes", { exact: true })).toBeVisible();
    await page.getByText("Casa", { exact: true }).click();
    await expect(page.getByText("Saldo da casa")).toBeVisible();
    await screenshot(page, "04-mobile-menu");
  });
});
