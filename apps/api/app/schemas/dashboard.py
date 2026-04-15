from decimal import Decimal

from app.schemas.common import ORMBaseModel


class DashboardAlert(ORMBaseModel):
    kind: str
    severity: str
    title: str
    message: str
    reference_id: str | None = None


class DashboardSummary(ORMBaseModel):
    total_balance: Decimal
    business_balance: Decimal
    personal_balance: Decimal
    total_entries: Decimal
    total_exits: Decimal
    total_to_receive: Decimal
    total_received: Decimal
    total_open: Decimal
    total_daniel_commission: Decimal
    owner_draw_total: Decimal
    monthly_subscription_burden: Decimal
    top_client_name: str | None = None
    top_client_share: Decimal = Decimal("0.00")
    top_platform_name: str | None = None
    top_platform_share: Decimal = Decimal("0.00")
    alerts: list[DashboardAlert]

