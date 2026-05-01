import { expect, test, type Locator, type Page } from '@playwright/test';

async function continueAfterManualLoginIfNeeded(page: Page) {
  const loginText = page.getByText(/faça login|login|entrar/i).first();
  if (await loginText.isVisible().catch(() => false)) {
    console.log('Faça login no navegador');
    await page.pause();
    await expect(loginText).toBeHidden({ timeout: 120_000 });
  }
}

async function fillVisibleInput(page: Page, index: number, value: string) {
  const fields = page.getByRole('textbox');
  await replaceText(page, fields.nth(index), value);
}

async function replaceText(
  page: Page,
  locator: Locator,
  value: string,
) {
  await locator.click();
  await page.keyboard.press('Control+A');
  await page.keyboard.type(value);
}

test.describe('Nexo fluxo financeiro', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    const accessibilityButton = page.getByRole('button', {
      name: 'Enable accessibility',
    });
    if (await accessibilityButton.isVisible().catch(() => false)) {
      await accessibilityButton.click();
    }
    await continueAfterManualLoginIfNeeded(page);
  });

  test('abre dashboard, cria cliente, projeto/pagamento e valida lucro', async ({
    page,
  }) => {
    await expect(page.getByText('Saldo geral')).toBeVisible();

    await page.getByRole('button', { name: 'Registrar', exact: true }).click();
    await page.getByRole('button', { name: /Novo cliente/ }).click();
    await expect(page.getByText('Novo cliente')).toBeVisible();
    await fillVisibleInput(page, 0, 'Cliente Playwright');
    await fillVisibleInput(page, 2, '11999990000');
    await page.getByText('Salvar cliente').click();
    await expect(page.getByText('Cliente salvo.').first()).toBeVisible();

    await page.getByRole('button', { name: 'Registrar', exact: true }).click();
    await page.getByRole('button', { name: /Nova venda/ }).click();
    await expect(page.getByText('Nova venda')).toBeVisible();
    await page.getByRole('textbox').first().click();
    await page.getByRole('button', { name: 'Cliente Playwright' }).click();
    await replaceText(
      page,
      page.getByRole('textbox', { name: 'Ex.: Landing page de campanha' }),
      'Projeto Playwright',
    );
    await replaceText(
      page,
      page.getByRole('textbox', { name: '0,00' }).first(),
      '5500',
    );
    await page.getByText('Daniel participou?').scrollIntoViewIfNeeded();
    await page.getByText('Sim').click();
    await expect(page.getByText('Daniel', { exact: true })).toBeVisible();
    await expect(page.getByText('R$ 1.650,00')).toBeVisible();
    await page.getByText('Salvar venda').click();
    await expect(page.getByText('Venda salva.').first()).toBeVisible();

    await page.getByText('Financeiro').click();
    await expect(page.getByText('Lucro real')).toBeVisible();
    await expect(page.getByText('R$ 3.850,00')).toBeVisible();
  });
});
