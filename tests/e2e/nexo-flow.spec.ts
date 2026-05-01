import { expect, test, type Page } from "@playwright/test";

async function enableAccessibilityIfNeeded(page: Page) {
  const accessibilityButton = page.getByRole("button", {
    name: "Enable accessibility",
  });
  if (await accessibilityButton.isVisible().catch(() => false)) {
    await accessibilityButton.click();
  }
}

async function screenshot(page: Page, name: string) {
  await page.screenshot({
    path: `test-results/${name}.png`,
    fullPage: true,
  });
}

async function clickNav(page: Page, label: string) {
  await page.getByText(label, { exact: true }).first().click();
}

test.describe("Nexo integracao final UI V2", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await enableAccessibilityIfNeeded(page);
  });

  test("modo foco abre e executa fluxos rapidos do dia", async ({ page }) => {
    await expect(page.getByText("Modo foco")).toBeVisible();
    await expect(
      page.getByText(/Melhor nao comprar|Voce pode gastar|Voce esta apertado/),
    ).toBeVisible();

    await page
      .getByRole("button", { name: /Recebi dinheiro|Recebi .+/ })
      .first()
      .click();
    const quickReceive = page.getByText("Recebi dinheiro").last();
    if (await quickReceive.isVisible().catch(() => false)) {
      await page.getByRole("textbox").nth(0).fill("Cliente E2E");
      await page.getByRole("textbox").nth(1).fill("1200");
      await page.getByText("Registrar agora").click();
      await expect(page.getByText("Dinheiro registrado.").first()).toBeVisible();
    }

    await page.getByRole("button", { name: "Adicionar gasto" }).first().click();
    await expect(page.getByText("Adicionar gasto").last()).toBeVisible();
    await page.getByRole("textbox").nth(0).fill("Internet E2E");
    await page.getByRole("textbox").nth(1).fill("199");
    await page.getByText("Registrar agora").click();
    await expect(page.getByText("Gasto registrado.").first()).toBeVisible();

    await page.getByRole("button", { name: "Cobrar cliente" }).first().click();
    await expect(page.getByText("Cobrar cliente").last()).toBeVisible();
    await screenshot(page, "01-hoje-modo-foco");
  });

  test("navegacao final mostra paginas dinamicas principais", async ({
    page,
  }) => {
    const pages = [
      "Casa",
      "Empresa",
      "Clientes",
      "Projetos",
      "Recebimentos",
      "Despesas",
      "Parceiros",
      "Assinaturas",
      "Planejamento",
      "Metas",
      "Inteligencia",
    ];

    for (const label of pages) {
      await clickNav(page, label);
      await expect(
        page.getByText(label, { exact: true }).first(),
      ).toBeVisible();
    }

    await screenshot(page, "02-sidebar-paginas");
  });

  test("valida planejamento, Daniel e recorrencia sem dados mockados", async ({
    page,
  }) => {
    await clickNav(page, "Planejamento");
    await expect(page.getByText("Resultado futuro")).toBeVisible();
    await expect(
      page.getByText(/7 dias|15 dias|30 dias/).first(),
    ).toBeVisible();
    await screenshot(page, "03-planejamento");

    await clickNav(page, "Parceiros");
    await expect(page.getByText("DANIEL", { exact: true })).toBeVisible();
    await expect(
      page.getByText(/Pago|Pendente|Sem repasse aberto/).first(),
    ).toBeVisible();
    await screenshot(page, "04-parceiros-daniel");

    await clickNav(page, "Assinaturas");
    await expect(
      page.getByText(/Clientes recorrentes|Gastos recorrentes/).first(),
    ).toBeVisible();
    await screenshot(page, "05-assinaturas-recorrencia");
  });
});
