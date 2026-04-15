from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import JSON, Boolean, Date, DateTime, Enum, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, SyncMixin
from app.models.enums import (
    AccountKind,
    BillingProfile,
    ClientStatus,
    ConflictStatus,
    IntegrationMode,
    IntegrationProvider,
    IntegrationStatus,
    PaymentMethod,
    Platform,
    SaleKind,
    SaleStatus,
    Scope,
    ServiceStage,
    SubscriptionCycle,
)


MONEY = Numeric(12, 2)


class Workspace(SyncMixin, Base):
    __tablename__ = "workspaces"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    currency: Mapped[str] = mapped_column(String(10), default="BRL")
    timezone: Mapped[str] = mapped_column(String(64), default="America/Sao_Paulo")
    default_partner_name: Mapped[str] = mapped_column(String(80), default="Daniel")
    default_partner_percent: Mapped[Decimal] = mapped_column(MONEY, default=Decimal("30.00"))
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class Account(SyncMixin, Base):
    __tablename__ = "accounts"

    workspace_id: Mapped[str] = mapped_column(ForeignKey("workspaces.id"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    scope: Mapped[Scope] = mapped_column(Enum(Scope), nullable=False, default=Scope.BUSINESS)
    kind: Mapped[AccountKind] = mapped_column(Enum(AccountKind), nullable=False, default=AccountKind.BANK)
    institution: Mapped[str | None] = mapped_column(String(120), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class Category(SyncMixin, Base):
    __tablename__ = "categories"

    workspace_id: Mapped[str] = mapped_column(ForeignKey("workspaces.id"), nullable=False, index=True)
    scope: Mapped[Scope] = mapped_column(Enum(Scope), nullable=False)
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    parent_name: Mapped[str | None] = mapped_column(String(80), nullable=True)
    system_default: Mapped[bool] = mapped_column(Boolean, default=False)


class Client(SyncMixin, Base):
    __tablename__ = "clients"

    workspace_id: Mapped[str] = mapped_column(ForeignKey("workspaces.id"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    email: Mapped[str | None] = mapped_column(String(180), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(40), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    lead_source: Mapped[str | None] = mapped_column(String(80), nullable=True)
    sales_platform: Mapped[Platform | None] = mapped_column(Enum(Platform), nullable=True)
    service_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    related_group: Mapped[str | None] = mapped_column(String(120), nullable=True)
    service_stage: Mapped[ServiceStage] = mapped_column(Enum(ServiceStage), default=ServiceStage.LEAD)
    status: Mapped[ClientStatus] = mapped_column(Enum(ClientStatus), default=ClientStatus.LEAD)
    billing_profile: Mapped[BillingProfile] = mapped_column(Enum(BillingProfile), default=BillingProfile.ONE_OFF)
    daniel_participation_default: Mapped[bool] = mapped_column(Boolean, default=False)


class Sale(SyncMixin, Base):
    __tablename__ = "sales"

    workspace_id: Mapped[str] = mapped_column(ForeignKey("workspaces.id"), nullable=False, index=True)
    client_id: Mapped[str | None] = mapped_column(ForeignKey("clients.id"), nullable=True, index=True)
    parent_sale_id: Mapped[str | None] = mapped_column(ForeignKey("sales.id"), nullable=True, index=True)
    destination_account_id: Mapped[str | None] = mapped_column(ForeignKey("accounts.id"), nullable=True)
    project_label: Mapped[str | None] = mapped_column(String(120), nullable=True)
    service_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    sale_kind: Mapped[SaleKind] = mapped_column(Enum(SaleKind), default=SaleKind.PRIMARY)
    scope: Mapped[Scope] = mapped_column(Enum(Scope), default=Scope.BUSINESS)
    platform: Mapped[Platform] = mapped_column(Enum(Platform), default=Platform.OTHER)
    payment_method: Mapped[PaymentMethod] = mapped_column(Enum(PaymentMethod), default=PaymentMethod.OTHER)
    gross_amount: Mapped[Decimal] = mapped_column(MONEY, nullable=False, default=Decimal("0.00"))
    platform_fee_amount: Mapped[Decimal] = mapped_column(MONEY, default=Decimal("0.00"))
    payment_fee_amount: Mapped[Decimal] = mapped_column(MONEY, default=Decimal("0.00"))
    net_amount: Mapped[Decimal] = mapped_column(MONEY, default=Decimal("0.00"))
    installment_count: Mapped[int] = mapped_column(default=1)
    sold_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    expected_receipt_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    received_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[SaleStatus] = mapped_column(Enum(SaleStatus), default=SaleStatus.PENDING)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    origin: Mapped[str | None] = mapped_column(String(120), nullable=True)
    daniel_involved: Mapped[bool] = mapped_column(Boolean, default=False)
    daniel_percent: Mapped[Decimal] = mapped_column(MONEY, default=Decimal("30.00"))
    commissionable_amount: Mapped[Decimal] = mapped_column(MONEY, default=Decimal("0.00"))
    daniel_amount: Mapped[Decimal] = mapped_column(MONEY, default=Decimal("0.00"))
    owner_net_amount: Mapped[Decimal] = mapped_column(MONEY, default=Decimal("0.00"))
    external_source: Mapped[str | None] = mapped_column(String(50), nullable=True)
    external_reference: Mapped[str | None] = mapped_column(String(120), nullable=True, index=True)
    external_event_name: Mapped[str | None] = mapped_column(String(120), nullable=True)


class Expense(SyncMixin, Base):
    __tablename__ = "expenses"

    workspace_id: Mapped[str] = mapped_column(ForeignKey("workspaces.id"), nullable=False, index=True)
    category_id: Mapped[str | None] = mapped_column(ForeignKey("categories.id"), nullable=True)
    paid_from_account_id: Mapped[str | None] = mapped_column(ForeignKey("accounts.id"), nullable=True)
    scope: Mapped[Scope] = mapped_column(Enum(Scope), nullable=False)
    description: Mapped[str] = mapped_column(String(160), nullable=False)
    subcategory_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    amount: Mapped[Decimal] = mapped_column(MONEY, nullable=False, default=Decimal("0.00"))
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    recurrence_rule: Mapped[str | None] = mapped_column(String(120), nullable=True)
    vendor_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class Subscription(SyncMixin, Base):
    __tablename__ = "subscriptions"

    workspace_id: Mapped[str] = mapped_column(ForeignKey("workspaces.id"), nullable=False, index=True)
    category_id: Mapped[str | None] = mapped_column(ForeignKey("categories.id"), nullable=True)
    account_id: Mapped[str | None] = mapped_column(ForeignKey("accounts.id"), nullable=True)
    scope: Mapped[Scope] = mapped_column(Enum(Scope), nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    responsible: Mapped[str | None] = mapped_column(String(100), nullable=True)
    cycle: Mapped[SubscriptionCycle] = mapped_column(Enum(SubscriptionCycle), default=SubscriptionCycle.MONTHLY)
    amount: Mapped[Decimal] = mapped_column(MONEY, nullable=False, default=Decimal("0.00"))
    renewal_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    next_renewal_at: Mapped[date | None] = mapped_column(Date, nullable=True)
    reminder_days_before: Mapped[int] = mapped_column(default=5)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class OwnerDraw(SyncMixin, Base):
    __tablename__ = "owner_draws"

    workspace_id: Mapped[str] = mapped_column(ForeignKey("workspaces.id"), nullable=False, index=True)
    from_account_id: Mapped[str | None] = mapped_column(ForeignKey("accounts.id"), nullable=True)
    to_account_id: Mapped[str | None] = mapped_column(ForeignKey("accounts.id"), nullable=True)
    amount: Mapped[Decimal] = mapped_column(MONEY, nullable=False, default=Decimal("0.00"))
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class IntegrationConnection(SyncMixin, Base):
    __tablename__ = "integration_connections"

    workspace_id: Mapped[str] = mapped_column(ForeignKey("workspaces.id"), nullable=False, index=True)
    provider: Mapped[IntegrationProvider] = mapped_column(Enum(IntegrationProvider), nullable=False)
    mode: Mapped[IntegrationMode] = mapped_column(Enum(IntegrationMode), nullable=False, default=IntegrationMode.MANUAL)
    status: Mapped[IntegrationStatus] = mapped_column(Enum(IntegrationStatus), nullable=False, default=IntegrationStatus.DISCONNECTED)
    external_account_label: Mapped[str | None] = mapped_column(String(120), nullable=True)
    config: Mapped[dict] = mapped_column(JSON, default=dict)
    last_sync_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_error: Mapped[str | None] = mapped_column(Text, nullable=True)


class WebhookEvent(SyncMixin, Base):
    __tablename__ = "webhook_events"

    workspace_id: Mapped[str | None] = mapped_column(ForeignKey("workspaces.id"), nullable=True, index=True)
    provider: Mapped[IntegrationProvider] = mapped_column(Enum(IntegrationProvider), nullable=False)
    external_event_id: Mapped[str | None] = mapped_column(String(120), nullable=True, index=True)
    event_name: Mapped[str] = mapped_column(String(120), nullable=False)
    is_test: Mapped[bool] = mapped_column(Boolean, default=False)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    received_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    processed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    processing_status: Mapped[str] = mapped_column(String(40), default="received")
    processing_error: Mapped[str | None] = mapped_column(Text, nullable=True)


class SyncConflict(SyncMixin, Base):
    __tablename__ = "sync_conflicts"

    workspace_id: Mapped[str | None] = mapped_column(ForeignKey("workspaces.id"), nullable=True, index=True)
    entity_type: Mapped[str] = mapped_column(String(80), nullable=False)
    entity_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    server_revision: Mapped[int] = mapped_column(nullable=False)
    client_revision: Mapped[int] = mapped_column(nullable=False)
    client_payload: Mapped[dict] = mapped_column(JSON, default=dict)
    server_payload: Mapped[dict] = mapped_column(JSON, default=dict)
    status: Mapped[ConflictStatus] = mapped_column(Enum(ConflictStatus), default=ConflictStatus.OPEN)
    resolution_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

