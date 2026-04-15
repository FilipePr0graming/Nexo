from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP


TWO_PLACES = Decimal("0.01")


def money(value: Decimal | float | int | str | None) -> Decimal:
    raw = Decimal("0.00") if value is None else Decimal(str(value))
    return raw.quantize(TWO_PLACES, rounding=ROUND_HALF_UP)


@dataclass(slots=True)
class SaleFinancials:
    net_amount: Decimal
    commissionable_amount: Decimal
    daniel_amount: Decimal
    owner_net_amount: Decimal


def calculate_sale_financials(
    *,
    gross_amount: Decimal,
    platform_fee_amount: Decimal = Decimal("0.00"),
    payment_fee_amount: Decimal = Decimal("0.00"),
    net_amount: Decimal | None = None,
    daniel_involved: bool = False,
    daniel_percent: Decimal = Decimal("30.00"),
    commissionable_amount: Decimal | None = None,
) -> SaleFinancials:
    gross_amount = money(gross_amount)
    platform_fee_amount = money(platform_fee_amount)
    payment_fee_amount = money(payment_fee_amount)
    daniel_percent = money(daniel_percent)

    computed_net = money(net_amount) if net_amount is not None else money(gross_amount - platform_fee_amount - payment_fee_amount)
    if computed_net < Decimal("0.00"):
        raise ValueError("O valor liquido nao pode ser negativo.")

    commission_base = money(commissionable_amount) if commissionable_amount is not None else computed_net
    daniel_amount = money(commission_base * (daniel_percent / Decimal("100"))) if daniel_involved else Decimal("0.00")
    owner_net_amount = money(computed_net - daniel_amount)
    if owner_net_amount < Decimal("0.00"):
        raise ValueError("A sobra final nao pode ficar negativa.")

    return SaleFinancials(
        net_amount=computed_net,
        commissionable_amount=commission_base,
        daniel_amount=daniel_amount,
        owner_net_amount=owner_net_amount,
    )

