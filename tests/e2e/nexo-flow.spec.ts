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
  "";
const supabaseAnonKey =
  env.NEXO_E2E_SUPABASE_ANON_KEY ??
  productionDefine.SUPABASE_ANON_KEY ??
  productionDefine.SUPABASE_PUBLISHABLE_KEY ??
  env.SUPABASE_ANON_KEY;
const serviceRoleKey =
  env.NEXO_E2E_SERVICE_ROLE_KEY ??
  (env.SUPABASE_URL === supabaseUrl ? env.SUPABASE_SERVICE_ROLE_KEY : undefined);
let userAccessToken: string | undefined;

const markerBase = "NEXO_UX_TEST_20260505_";
const runId = env.NEXO_E2E_RUN_ID ?? `${markerBase}${Date.now()}`;
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

function loadJson(file: string): Record<string, string> {
  if (!existsSync(file)) {
    return {};
  }
  return JSON.parse(readFileSync(file, "utf8")) as Record<string, string>;
}

async function ensureSupabaseAccess() {
  if (serviceRoleKey || userAccessToken || !supabaseAnonKey || !supabaseUrl) {
    return;
  }

  let response = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: {
      apikey: supabaseAnonKey,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ email, password }),
  });
  if (!response.ok) {
    await fetch(`${supabaseUrl}/auth/v1/signup`, {
      method: "POST",
      headers: {
        apikey: supabaseAnonKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, password }),
    }).catch(() => null);
    response = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
      method: "POST",
      headers: {
        apikey: supabaseAnonKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, password }),
    });
  }
  if (!response.ok) {
    throw new Error(`Login remoto falhou: ${await response.text()}`);
  }
  const body = (await response.json()) as { access_token?: string };
  userAccessToken = body.access_token;
}

async function supabaseFetch(pathname: string, init: RequestInit = {}) {
  await ensureSupabaseAccess();
  const apiKey = serviceRoleKey ?? supabaseAnonKey;
  const bearer = serviceRoleKey ?? userAccessToken;
  if (!apiKey || !bearer || !supabaseUrl) {
    throw new Error("Credenciais remotas ausentes para o E2E.");
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

function cleanupPatterns() {
  return [
    markerBase,
    "NEXO_WINDOWS_TEST_20260505_",
    "NEXO_UX_TEST_",
    "NEXO_SAFE_TEST_",
    "NEXO_VISUAL_TEST_",
    "NEXO_SIMPLIFY_TEST_",
    "E2E_CLEANED_",
    "CLEANED_RECORD",
    "CLEANED_",
    "E2E_",
    "SAFE_TEST",
    "DEBUG",
  ];
}

async function cleanupByPattern(pattern: string) {
  const encodedRun = encodeURIComponent(`*${pattern}*`);
  const targets = [
    `/rest/v1/notes?or=(title.ilike.${encodedRun},body.ilike.${encodedRun})`,
    `/rest/v1/reminders?or=(title.ilike.${encodedRun},description.ilike.${encodedRun})`,
    `/rest/v1/goals?title=ilike.${encodedRun}`,
    `/rest/v1/payments?or=(client_name.ilike.${encodedRun},service_name.ilike.${encodedRun},project_group.ilike.${encodedRun},notes.ilike.${encodedRun})`,
    `/rest/v1/projects?or=(name.ilike.${encodedRun},notes.ilike.${encodedRun})`,
    `/rest/v1/subscriptions?or=(name.ilike.${encodedRun},notes.ilike.${encodedRun})`,
    `/rest/v1/expenses?or=(title.ilike.${encodedRun},category.ilike.${encodedRun},notes.ilike.${encodedRun})`,
    `/rest/v1/clients?or=(name.ilike.${encodedRun},legal_name.ilike.${encodedRun},notes.ilike.${encodedRun},origin.ilike.${encodedRun})`,
  ];

  for (const target of targets) {
    await supabaseFetchOrEmpty(target, { method: "DELETE" });
  }
}

async function cleanupE2eData() {
  for (const pattern of cleanupPatterns()) {
    await cleanupByPattern(pattern);
  }
}

async function countResidues() {
  let total = 0;
  for (const pattern of cleanupPatterns()) {
    const encodedRun = encodeURIComponent(`*${pattern}*`);
    const targets = [
      `/rest/v1/clients?select=id&or=(name.ilike.${encodedRun},legal_name.ilike.${encodedRun},notes.ilike.${encodedRun},origin.ilike.${encodedRun})`,
      `/rest/v1/projects?select=id&or=(name.ilike.${encodedRun},notes.ilike.${encodedRun})`,
      `/rest/v1/payments?select=id&or=(client_name.ilike.${encodedRun},service_name.ilike.${encodedRun},project_group.ilike.${encodedRun},notes.ilike.${encodedRun})`,
      `/rest/v1/expenses?select=id&or=(title.ilike.${encodedRun},category.ilike.${encodedRun},notes.ilike.${encodedRun})`,
      `/rest/v1/notes?select=id&or=(title.ilike.${encodedRun},body.ilike.${encodedRun})`,
      `/rest/v1/goals?select=id&title=ilike.${encodedRun}`,
      `/rest/v1/reminders?select=id&or=(title.ilike.${encodedRun},description.ilike.${encodedRun})`,
      `/rest/v1/subscriptions?select=id&or=(name.ilike.${encodedRun},notes.ilike.${encodedRun})`,
    ];
    const rows = await Promise.all(
      targets.map(
        (target) => supabaseFetchOrEmpty(target) as Promise<Array<unknown>>,
      ),
    );
    total += rows.reduce((sum, items) => sum + items.length, 0);
  }
  return total;
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
  const home = page.getByText(/Saldo disponível|Fazer hoje|Ações rápidas/);
  if (await home.first().isVisible({ timeout: 5000 }).catch(() => false)) {
    return;
  }

  const loginButton = page.getByRole("button", { name: "Entrar" });
  await expect(loginButton).toBeVisible();
  await fillTextbox(page, 0, email);
  await fillTextbox(page, 1, password);
  await loginButton.click();
  await expect(home.first()).toBeVisible({ timeout: 45000 });
}

async function fillTextbox(page: Page, index: number, value: string) {
  const field = page.getByRole("textbox").nth(index);
  await field.click();
  await page.keyboard.press("Control+A");
  await page.keyboard.press("Backspace");
  await page.keyboard.type(value);
  await expect.poll(async () => field.inputValue(), { timeout: 5000 }).toBe(value);
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
  const button = page
    .getByRole("button", { name: new RegExp(`^${escapeRegExp(label)}$`) })
    .first();
  if (await button.isVisible().catch(() => false)) {
    await button.click({ force: true });
    return;
  }
  await page.getByText(label, { exact: true }).first().click({ force: true });
}

async function closeTopLayer(page: Page) {
  await page.keyboard.press("Escape");
  await page.waitForTimeout(350);
}

async function openQuickAction(page: Page, action: string) {
  await page.getByRole("button", { name: "Registrar" }).click();
  await expect(page.getByText("Registrar", { exact: true })).toBeVisible();
  await page.getByText(action, { exact: true }).click();
}

async function expectForbiddenUiGone(page: Page) {
  await expect(
    page.getByText(
      /Finan\/ças|Calculado\.\.\.|Proje\/tos|Clientes para decidir|Sugestões automáticas|Sugestoes automaticas|Inteligência financeira indisponível|Inteligencia financeira indisponivel|E2E|CLEANED|NEXO_SAFE_TEST|NEXO_VISUAL_TEST|NEXO_SIMPLIFY_TEST|NEXO_UX_TEST|DEBUG|\bTEST\b/,
    ),
  ).toHaveCount(0);
}

async function expectNoHorizontalOverflow(page: Page) {
  await expect
    .poll(async () => {
      return page.evaluate(
        () => document.documentElement.scrollWidth <= window.innerWidth + 1,
      );
    })
    .toBe(true);
}

async function exerciseMarkerLifecycle() {
  const marker = `${markerBase}${Date.now()}`;
  const id = `note-${Date.now()}`;
  const now = new Date().toISOString();
  await supabaseFetch("/rest/v1/notes", {
    method: "POST",
    body: JSON.stringify({
      id,
      title: marker,
      body: `${marker} criado`,
      created_at: now,
      updated_at: now,
    }),
  });
  await supabaseFetch(`/rest/v1/notes?id=eq.${encodeURIComponent(id)}`, {
    method: "PATCH",
    body: JSON.stringify({
      title: `${marker} editado`,
      body: `${marker} editado`,
      updated_at: new Date().toISOString(),
    }),
  });
  await supabaseFetch(`/rest/v1/notes?id=eq.${encodeURIComponent(id)}`, {
    method: "DELETE",
  });
  expect(await countResidues()).toBe(0);
}

test.describe.configure({ mode: "serial" });

test.beforeAll(async () => {
  expect(supabaseUrl).not.toContain("127.0.0.1");
  await ensureE2eUser();
  await cleanupE2eData();
});

test.afterAll(async () => {
  await cleanupE2eData();
  expect(await countResidues()).toBe(0);
});

test.describe("NEXO UX final", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test.afterEach(async () => {
    await cleanupE2eData();
  });

  test("mobile hoje, rodape, botao registrar e acoes", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await login(page);
    await expect(page.getByText("Hoje", { exact: true }).first()).toBeVisible();
    await expect(page.getByText("Saldo disponível")).toBeVisible();
    await expect(page.getByText("Fazer hoje")).toBeVisible();
    await expect(page.getByText("Ações rápidas")).toBeVisible();
    await expect(page.getByText("Calculadora", { exact: true })).toHaveCount(0);
    await expectForbiddenUiGone(page);

    for (const label of ["Hoje", "Clientes", "Finanças", "Menu"]) {
      await expect(
        page.getByRole("button", { name: new RegExp(`^${label}$`) }).first(),
      ).toBeVisible();
    }

    const fabBox = await page
      .getByRole("button", { name: "Registrar" })
      .boundingBox();
    const menuBox = await page
      .getByRole("button", { name: "Menu" })
      .first()
      .boundingBox();
    expect(fabBox).not.toBeNull();
    expect(menuBox).not.toBeNull();
    expect(fabBox!.y + fabBox!.height).toBeLessThan(menuBox!.y);
    await expectNoHorizontalOverflow(page);
    await screenshot(page, "mobile-hoje");

    await page.getByRole("button", { name: "Registrar" }).click();
    for (const action of [
      "Recebi dinheiro",
      "Paguei conta",
      "Registrei gasto",
      "Cobrar cliente",
      "Criar lembrete",
      "Nova anotação",
      "Calculadora",
    ]) {
      await expect(page.getByText(action, { exact: true })).toBeVisible();
    }
    await screenshot(page, "mobile-botao-registrar");
    await closeTopLayer(page);

    await openQuickAction(page, "Recebi dinheiro");
    await expect(page.getByText("Nova venda", { exact: true })).toBeVisible();
    await page.getByRole("button", { name: "Fechar" }).click();

    await openQuickAction(page, "Paguei conta");
    await expect(page.getByText("Novo gasto", { exact: true })).toBeVisible();
    await page.getByRole("button", { name: "Fechar" }).click();

    await openQuickAction(page, "Registrei gasto");
    await expect(page.getByText("Novo gasto", { exact: true })).toBeVisible();
    await page.getByRole("button", { name: "Fechar" }).click();

    await openQuickAction(page, "Cobrar cliente");
    await expect(page.getByText("Cobrar cliente", { exact: true })).toBeVisible();
    await closeTopLayer(page);

    await openQuickAction(page, "Criar lembrete");
    await expect(page.getByText("Criar lembrete", { exact: true })).toBeVisible();
    await closeTopLayer(page);

    await openQuickAction(page, "Nova anotação");
    await expect(page.getByText("Nova anotação", { exact: true })).toBeVisible();
    await closeTopLayer(page);

    await openQuickAction(page, "Calculadora");
    await expect(page.getByText("Calculadora", { exact: true }).first()).toBeVisible();
    await clickNav(page, "Hoje");
  });

  test("mobile clientes, financas e menu", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await clickNav(page, "Clientes");
    await expect(page.getByText("Clientes", { exact: true }).first()).toBeVisible();
    await expect(page.getByText(/Anderson Ferreira Augusto|Anderson/i).first()).toBeVisible();
    await expect(page.getByText(/Aberto:\s*R\$\s*725,00|Aberto:/).first()).toBeVisible();
    await expect(page.getByText(/Tam[ií]ris|Tamires|DB Locadora/i).first()).toBeVisible();
    await expect(page.getByText("Status: Em dia").first()).toBeVisible();

    await clickNav(page, "Finanças");
    await expect(page.getByText("Finanças", { exact: true }).first()).toBeVisible();
    await expect(page.getByText("Saldo disponível")).toBeVisible();
    await expect(page.getByText(/Cora.*Fatura Abril|Fatura abril Cora/i)).toBeVisible();
    await expect(page.getByText("Supermercado Nobre")).toBeVisible();
    await expect(page.getByText("Transferência Cora Pix -> BTG")).toBeVisible();
    await screenshot(page, "mobile-financas");

    await clickNav(page, "Menu");
    await expect(page.getByText("Menu", { exact: true }).first()).toBeVisible();
    for (const item of [
      "Projetos",
      "Parceiros",
      "Planejamento",
      "Metas",
      "Anotações",
      "Calculadora",
      "Casa",
      "Empresa",
      "Configurações",
    ]) {
      await expect(page.getByText(item, { exact: true }).first()).toBeVisible();
    }
    await screenshot(page, "mobile-menu");
    await expectForbiddenUiGone(page);
  });

  test("desktop sidebar, layout e financas", async ({ page }) => {
    await page.setViewportSize({ width: 1366, height: 768 });
    await login(page);
    await expect(page.getByText("Hoje", { exact: true }).first()).toBeVisible();
    await expect(page.getByText("Projetos", { exact: true }).first()).toBeVisible();
    await expect(page.getByText("Planejamento", { exact: true }).first()).toBeVisible();
    await expect(page.getByRole("button", { name: "Registrar" })).toBeVisible();
    await expectNoHorizontalOverflow(page);
    await expectForbiddenUiGone(page);
    await screenshot(page, "desktop-hoje");

    await clickNav(page, "Finanças");
    await expect(page.getByText("Cartões")).toBeVisible();
    await expect(page.getByText("Bancos")).toBeVisible();
    await expect(page.getByText("Movimentos")).toBeVisible();
    await expect(page.getByText("Transferência Cora Pix -> BTG")).toBeVisible();
    await expectNoHorizontalOverflow(page);
    await screenshot(page, "desktop-financas");

    await exerciseMarkerLifecycle();
  });
});
