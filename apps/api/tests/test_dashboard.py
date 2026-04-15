from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.models.base import Base
from app.models.entities import Expense, OwnerDraw, Sale, Workspace
from app.models.enums import PaymentMethod, Platform, SaleStatus, Scope
from app.services.dashboard import build_dashboard_summary


def test_dashboard_summary_splits_business_and_personal() -> None:
    engine = create_engine("sqlite:///:memory:", future=True)
    TestingSession = sessionmaker(bind=engine, autocommit=False, autoflush=False, expire_on_commit=False)
    Base.metadata.create_all(bind=engine)

    with TestingSession() as session:
        workspace = Workspace(name="Teste", currency="BRL", timezone="America/Sao_Paulo", default_partner_name="Daniel")
        session.add(workspace)
        session.flush()

        session.add(
            Sale(
                workspace_id=workspace.id,
                scope=Scope.BUSINESS,
                platform=Platform.MANUAL,
                payment_method=PaymentMethod.PIX,
                gross_amount=Decimal("1000.00"),
                platform_fee_amount=Decimal("0.00"),
                payment_fee_amount=Decimal("0.00"),
                net_amount=Decimal("1000.00"),
                owner_net_amount=Decimal("1000.00"),
                commissionable_amount=Decimal("1000.00"),
                daniel_amount=Decimal("0.00"),
                sold_at=datetime.now(timezone.utc),
                status=SaleStatus.RECEIVED,
            )
        )
        session.add(
            Expense(
                workspace_id=workspace.id,
                scope=Scope.BUSINESS,
                description="Internet",
                amount=Decimal("200.00"),
                occurred_at=datetime.now(timezone.utc),
            )
        )
        session.add(
            Expense(
                workspace_id=workspace.id,
                scope=Scope.PERSONAL,
                description="Mercado",
                amount=Decimal("150.00"),
                occurred_at=datetime.now(timezone.utc),
            )
        )
        session.add(
            OwnerDraw(
                workspace_id=workspace.id,
                amount=Decimal("300.00"),
                occurred_at=datetime.now(timezone.utc),
            )
        )
        session.commit()

        summary = build_dashboard_summary(session)

    assert summary.business_balance == Decimal("500.00")
    assert summary.personal_balance == Decimal("150.00")
    assert summary.total_balance == Decimal("650.00")

