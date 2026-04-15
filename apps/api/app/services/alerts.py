from __future__ import annotations

from collections import defaultdict
from datetime import datetime, timezone
from decimal import Decimal

from app.models.entities import Account, Client, Expense, Sale
from app.models.enums import SaleStatus, Scope
from app.schemas.dashboard import DashboardAlert


def build_alerts(
    *,
    sales: list[Sale],
    expenses: list[Expense],
    accounts: dict[str, Account],
    clients: dict[str, Client],
    now: datetime | None = None,
) -> list[DashboardAlert]:
    now = now or datetime.now(timezone.utc)
    alerts: list[DashboardAlert] = []

    overdue_sales = [sale for sale in sales if sale.deleted_at is None and sale.status == SaleStatus.OVERDUE]
    if overdue_sales:
        total_overdue = sum((sale.owner_net_amount for sale in overdue_sales), Decimal("0.00"))
        alerts.append(
            DashboardAlert(
                kind="overdue_receivables",
                severity="high",
                title="Recebimentos atrasados",
                message=f"Existem {len(overdue_sales)} vendas atrasadas somando {total_overdue}.",
            )
        )

    mixed_expenses = []
    for expense in expenses:
        if expense.deleted_at is not None or not expense.paid_from_account_id:
            continue
        account = accounts.get(expense.paid_from_account_id)
        if account and account.scope != expense.scope:
            mixed_expenses.append(expense)
    if mixed_expenses:
        alerts.append(
            DashboardAlert(
                kind="mixed_scope_expenses",
                severity="medium",
                title="Mistura entre pessoal e empresa",
                message=f"Foram encontrados {len(mixed_expenses)} gastos com escopo diferente da conta pagadora.",
            )
        )

    business_received = sum(
        (
            sale.owner_net_amount
            for sale in sales
            if sale.deleted_at is None and sale.scope == Scope.BUSINESS and sale.status == SaleStatus.RECEIVED
        ),
        Decimal("0.00"),
    )
    business_expenses = sum(
        (expense.amount for expense in expenses if expense.deleted_at is None and expense.scope == Scope.BUSINESS),
        Decimal("0.00"),
    )
    if business_received > Decimal("0.00") and business_expenses > business_received * Decimal("0.70"):
        alerts.append(
            DashboardAlert(
                kind="expense_pressure",
                severity="medium",
                title="Gastos altos em relacao ao recebido",
                message="As despesas da empresa consumiram mais de 70% do valor ja recebido.",
            )
        )

    client_revenue: dict[str, Decimal] = defaultdict(lambda: Decimal("0.00"))
    total_revenue = Decimal("0.00")
    for sale in sales:
        if sale.deleted_at is not None or sale.status in {SaleStatus.CANCELED, SaleStatus.REFUNDED}:
            continue
        total_revenue += sale.gross_amount
        if sale.client_id:
            client_revenue[sale.client_id] += sale.gross_amount

    if total_revenue > Decimal("0.00") and client_revenue:
        top_client_id = max(client_revenue, key=client_revenue.get)
        share = client_revenue[top_client_id] / total_revenue
        if share >= Decimal("0.45"):
            alerts.append(
                DashboardAlert(
                    kind="revenue_concentration",
                    severity="low",
                    title="Concentracao de receita",
                    message=f"O cliente {clients.get(top_client_id).name if clients.get(top_client_id) else top_client_id} representa mais de 45% da receita registrada.",
                    reference_id=top_client_id,
                )
            )

    return alerts

