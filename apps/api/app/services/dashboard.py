from __future__ import annotations

from collections import defaultdict
from datetime import datetime
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.entities import Account, Client, Expense, OwnerDraw, Sale, Subscription
from app.models.enums import SaleStatus, Scope, SubscriptionCycle
from app.schemas.dashboard import DashboardSummary
from app.services.alerts import build_alerts


def _within_window(value: datetime | None, start: datetime | None, end: datetime | None) -> bool:
    if value is None:
        return False
    if start and value < start:
        return False
    if end and value > end:
        return False
    return True


def _monthly_equivalent(subscription: Subscription) -> Decimal:
    if subscription.cycle == SubscriptionCycle.MONTHLY:
        return subscription.amount
    if subscription.cycle == SubscriptionCycle.ANNUAL:
        return (subscription.amount / Decimal("12")).quantize(Decimal("0.01"))
    return subscription.amount


def build_dashboard_summary(session: Session, *, start: datetime | None = None, end: datetime | None = None) -> DashboardSummary:
    sales = session.scalars(select(Sale)).all()
    expenses = session.scalars(select(Expense)).all()
    subscriptions = session.scalars(select(Subscription)).all()
    owner_draws = session.scalars(select(OwnerDraw)).all()
    clients = {client.id: client for client in session.scalars(select(Client)).all()}
    accounts = {account.id: account for account in session.scalars(select(Account)).all()}

    active_sales = [sale for sale in sales if sale.deleted_at is None and _within_window(sale.sold_at, start, end)]
    active_expenses = [expense for expense in expenses if expense.deleted_at is None and _within_window(expense.occurred_at, start, end)]
    active_draws = [draw for draw in owner_draws if draw.deleted_at is None and _within_window(draw.occurred_at, start, end)]
    active_subscriptions = [sub for sub in subscriptions if sub.deleted_at is None and sub.is_active]

    total_entries = sum(
        (sale.gross_amount for sale in active_sales if sale.status not in {SaleStatus.CANCELED, SaleStatus.REFUNDED}),
        Decimal("0.00"),
    )
    total_exits = sum((expense.amount for expense in active_expenses), Decimal("0.00"))
    total_to_receive = sum(
        (sale.owner_net_amount for sale in active_sales if sale.status in {SaleStatus.PENDING, SaleStatus.OVERDUE}),
        Decimal("0.00"),
    )
    total_received = sum(
        (sale.owner_net_amount for sale in active_sales if sale.status == SaleStatus.RECEIVED),
        Decimal("0.00"),
    )
    total_open = sum(
        (sale.owner_net_amount for sale in active_sales if sale.status == SaleStatus.OVERDUE),
        Decimal("0.00"),
    )
    total_daniel_commission = sum(
        (sale.daniel_amount for sale in active_sales if sale.status not in {SaleStatus.CANCELED, SaleStatus.REFUNDED}),
        Decimal("0.00"),
    )
    owner_draw_total = sum((draw.amount for draw in active_draws), Decimal("0.00"))
    monthly_subscription_burden = sum((_monthly_equivalent(sub) for sub in active_subscriptions), Decimal("0.00"))

    business_received = sum(
        (
            sale.owner_net_amount
            for sale in sales
            if sale.deleted_at is None and sale.scope == Scope.BUSINESS and sale.status == SaleStatus.RECEIVED
        ),
        Decimal("0.00"),
    )
    personal_received = sum(
        (
            sale.owner_net_amount
            for sale in sales
            if sale.deleted_at is None and sale.scope == Scope.PERSONAL and sale.status == SaleStatus.RECEIVED
        ),
        Decimal("0.00"),
    )
    business_expenses = sum(
        (expense.amount for expense in expenses if expense.deleted_at is None and expense.scope == Scope.BUSINESS),
        Decimal("0.00"),
    )
    personal_expenses = sum(
        (expense.amount for expense in expenses if expense.deleted_at is None and expense.scope == Scope.PERSONAL),
        Decimal("0.00"),
    )
    business_balance = business_received - business_expenses - owner_draw_total
    personal_balance = personal_received + owner_draw_total - personal_expenses
    total_balance = business_balance + personal_balance

    client_totals: dict[str, Decimal] = defaultdict(lambda: Decimal("0.00"))
    platform_totals: dict[str, Decimal] = defaultdict(lambda: Decimal("0.00"))
    revenue_base = Decimal("0.00")
    for sale in active_sales:
        if sale.status in {SaleStatus.CANCELED, SaleStatus.REFUNDED}:
            continue
        revenue_base += sale.gross_amount
        if sale.client_id:
            client_totals[sale.client_id] += sale.gross_amount
        platform_totals[sale.platform.value] += sale.gross_amount

    top_client_name = None
    top_client_share = Decimal("0.00")
    if client_totals and revenue_base > Decimal("0.00"):
        client_id = max(client_totals, key=client_totals.get)
        top_client_name = clients.get(client_id).name if clients.get(client_id) else None
        top_client_share = (client_totals[client_id] / revenue_base).quantize(Decimal("0.01"))

    top_platform_name = None
    top_platform_share = Decimal("0.00")
    if platform_totals and revenue_base > Decimal("0.00"):
        platform_name = max(platform_totals, key=platform_totals.get)
        top_platform_name = platform_name
        top_platform_share = (platform_totals[platform_name] / revenue_base).quantize(Decimal("0.01"))

    alerts = build_alerts(sales=sales, expenses=expenses, accounts=accounts, clients=clients)
    return DashboardSummary(
        total_balance=total_balance,
        business_balance=business_balance,
        personal_balance=personal_balance,
        total_entries=total_entries,
        total_exits=total_exits,
        total_to_receive=total_to_receive,
        total_received=total_received,
        total_open=total_open,
        total_daniel_commission=total_daniel_commission,
        owner_draw_total=owner_draw_total,
        monthly_subscription_burden=monthly_subscription_burden,
        top_client_name=top_client_name,
        top_client_share=top_client_share,
        top_platform_name=top_platform_name,
        top_platform_share=top_platform_share,
        alerts=alerts,
    )

