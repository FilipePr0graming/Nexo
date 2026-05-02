import { expect, test, type Page } from "@playwright/test";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";

const env = loadEnv();
const supabaseUrl = env.SUPABASE_URL ?? "http://127.0.0.1:54321";
const serviceRoleKey = env.SUPABASE_SERVICE_ROLE_KEY;
const runId = env.NEXO_E2E_RUN_ID ?? `e2e-${Date.now()}`;
const email = env.NEXO_E2E_EMAIL ?? `nexo-${runId}@example.com`;
const password = env.NEXO_E2E_PASSWORD ?? "NexoE2e!23456";

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

async function supabaseFetch(pathname: string, init: RequestInit = {}) {
  if (!serviceRoleKey) {
    throw new Error("SUPABASE_SERVICE_ROLE_KEY ausente no .env.");
  }

  const response = await fetch(`${supabaseUrl}${pathname}`, {
    ...init,
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
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

async function ensureE2eUser() {
  if (!serviceRoleKey) {
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
  if (!serviceRoleKey) {
    return;
  }

  const encodedRun = encodeURIComponent(`*${runId}*`);
  const payments = (await supabaseFetch(
    `/rest/v1/payments?select=id&or=(client_name.ilike.${encodedRun},service_name.ilike.${encodedRun},project_group.ilike.${encodedRun},notes.ilike.${encodedRun})`,
  )) as Array<{ id: string }>;
  const paymentIds = payments.map((payment) => payment.id);

  if (paymentIds.length > 0) {
    await supabaseFetch(
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
    await supabaseFetch(target, { method: "DELETE" });
  }
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
  const dashboard = page.getByText("Modo foco");
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
  await expect
    .poll(
      async () => {
        const rows = (await supabaseFetch(
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
});

test.describe("Nexo integracao final", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("login e dashboard inteligente", async ({ page }) => {
    await expect(page.getByText("Modo foco")).toBeVisible();
    await expect(page.getByText("Caixa real")).toBeVisible();
    await expect(page.getByText(/7 dias|15 dias|30 dias/).first()).toBeVisible();
    await screenshot(page, "01-dashboard");
  });

  test("clientes, projetos, pagamentos, gastos e recebimento", async ({
    page,
  }) => {
    await clickNav(page, "Clientes");
    await page.getByRole("button", { name: "Novo cliente" }).first().click();
    await expect(page.getByText("Novo cliente")).toBeVisible();
    await fillTextbox(page, 0, `Cliente ${runId}`);
    await fillTextbox(page, 1, "00000000000");
    await fillTextbox(page, 3, `origem ${runId}`);
    await page.getByRole("button", { name: "Salvar cliente" }).click();
    await expect(recordByLabel(page, `Cliente ${runId}`)).toBeVisible();

    await clickNav(page, "Projetos");
    await page.getByRole("button", { name: "Novo projeto" }).first().click();
    await fillTextbox(page, 0, `Projeto ${runId}`);
    await fillTextbox(page, 1, `Cliente ${runId}`);
    await fillTextbox(page, 3, "5500");
    await fillTextbox(page, 4, `projeto ${runId}`);
    await page.getByRole("button", { name: "Salvar projeto" }).click();
    await expect(recordByLabel(page, `Projeto ${runId}`)).toBeVisible();

    await page.getByRole("button", { name: "Venda" }).first().click();
    await page.getByRole("textbox").nth(0).click();
    await page.getByText(`Cliente ${runId}`).last().click();
    await fillTextbox(page, 1, `Pix ${runId}`);
    await fillTextbox(page, 2, `Projeto ${runId}`);
    await fillTextbox(page, 4, "5500");
    await page.getByText("Sim").click();
    await page.getByRole("button", { name: "Salvar venda" }).click();
    await expectButtonGone(page, "Salvar venda");
    await expect(page.getByText("Venda salva.").first()).toBeVisible();

    await clickNav(page, "Projetos");
    await page.getByRole("button", { name: "Venda" }).first().click();
    await page.getByRole("textbox").nth(0).click();
    await page.getByText(`Cliente ${runId}`).last().click();
    await fillTextbox(page, 1, `Cartao ${runId}`);
    await fillTextbox(page, 2, `Projeto ${runId}`);
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
    await fillTextbox(page, 0, "199");
    await clickSelect(page, "Recorrencia");
    await page.getByText("Mensal").click();
    await fillTextbox(page, 1, `Internet ${runId}`);
    await page.getByRole("button", { name: "Salvar gasto" }).click();
    await expectButtonGone(page, "Salvar gasto");
    await expect(page.getByText("Gasto salvo.").first()).toBeVisible();

    await clickNav(page, "Hoje");
    await page
      .getByRole("button", {
        name: new RegExp(`Recebi.*Cartao ${escapeRegExp(runId)}`),
      })
      .first()
      .click();
    await expectPaymentStatus(`Cartao ${runId}`, "received");
    await screenshot(page, "02-fluxos-financeiros");
  });

  test("metas, anotacoes, planejamento e parceiro Daniel", async ({
    page,
  }) => {
    await clickNav(page, "Metas");
    await page.getByRole("button", { name: "Nova meta" }).first().click();
    await fillTextbox(page, 0, `Meta ${runId}`);
    await fillTextbox(page, 1, "8000");
    await fillTextbox(page, 2, "1200");
    await page.getByRole("button", { name: "Salvar meta" }).click();
    await expect(recordByLabel(page, `Meta ${runId}`)).toBeVisible();

    await clickNav(page, "Anotacoes");
    await page.getByRole("button", { name: "Nova anotacao" }).first().click();
    await fillTextbox(page, 0, `Nota ${runId}`);
    await fillTextbox(page, 1, `Conteudo da nota ${runId}`);
    await page.getByRole("button", { name: "Salvar anotacao" }).click();
    await expect(recordByLabel(page, `Nota ${runId}`)).toBeVisible();

    await clickNav(page, "Planejamento");
    await expect(page.getByText("Resultado futuro")).toBeVisible();
    await expect(page.getByText("Alertas e lembretes")).toBeVisible();

    await clickNav(page, "Parceiros");
    await expect(page.getByText("Daniel").first()).toBeVisible();
    await expect(
      page.getByText(/Debitos no Supabase|Por projeto/).first(),
    ).toBeVisible();
    await screenshot(page, "03-metas-notas-planejamento-parceiros");

    await clickNav(page, "Anotacoes");
    await page.getByRole("button", { name: "Excluir anotacao" }).first().click();
    await expect(page.getByLabel(new RegExp(`Nota ${escapeRegExp(runId)}`))).toHaveCount(0);

    await clickNav(page, "Metas");
    await page.getByRole("button", { name: "Excluir meta" }).first().click();
    await expect(page.getByLabel(new RegExp(`Meta ${escapeRegExp(runId)}`))).toHaveCount(0);
  });

  test("responsividade mobile com menu lateral colapsavel", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await expect(page.getByText("Hoje", { exact: true }).first()).toBeVisible();
    await page.getByText("Menu", { exact: true }).click();
    await expect(page.getByText("Anotacoes", { exact: true })).toBeVisible();
    await page.getByText("Casa", { exact: true }).click();
    await expect(page.getByText("Saldo da casa")).toBeVisible();
    await screenshot(page, "04-mobile-menu");
  });
});
