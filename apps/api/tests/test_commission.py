from decimal import Decimal

from app.services.commission import calculate_sale_financials


def test_calculate_sale_financials_with_partner() -> None:
    result = calculate_sale_financials(
        gross_amount=Decimal("1000.00"),
        platform_fee_amount=Decimal("100.00"),
        payment_fee_amount=Decimal("50.00"),
        daniel_involved=True,
        daniel_percent=Decimal("30.00"),
    )

    assert result.net_amount == Decimal("850.00")
    assert result.commissionable_amount == Decimal("850.00")
    assert result.daniel_amount == Decimal("255.00")
    assert result.owner_net_amount == Decimal("595.00")


def test_calculate_sale_financials_with_partial_commission_base() -> None:
    result = calculate_sale_financials(
        gross_amount=Decimal("1000.00"),
        platform_fee_amount=Decimal("100.00"),
        payment_fee_amount=Decimal("50.00"),
        daniel_involved=True,
        daniel_percent=Decimal("30.00"),
        commissionable_amount=Decimal("400.00"),
    )

    assert result.net_amount == Decimal("850.00")
    assert result.commissionable_amount == Decimal("400.00")
    assert result.daniel_amount == Decimal("120.00")
    assert result.owner_net_amount == Decimal("730.00")

