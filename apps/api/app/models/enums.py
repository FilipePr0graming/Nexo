from enum import Enum


class Scope(str, Enum):
    BUSINESS = "business"
    PERSONAL = "personal"


class AccountKind(str, Enum):
    BANK = "bank"
    CASH = "cash"
    WALLET = "wallet"
    CARD = "card"


class ClientStatus(str, Enum):
    LEAD = "lead"
    ACTIVE = "active"
    IN_PROGRESS = "in_progress"
    PAUSED = "paused"
    COMPLETED = "completed"
    LOST = "lost"


class BillingProfile(str, Enum):
    MONTHLY = "monthly"
    ONE_OFF = "one_off"


class ServiceStage(str, Enum):
    LEAD = "lead"
    NEGOTIATION = "negotiation"
    ONBOARDING = "onboarding"
    EXECUTION = "execution"
    REVIEW = "review"
    DELIVERED = "delivered"
    RETENTION = "retention"


class SaleStatus(str, Enum):
    PENDING = "pending"
    RECEIVED = "received"
    OVERDUE = "overdue"
    CANCELED = "canceled"
    REFUNDED = "refunded"


class SaleKind(str, Enum):
    PRIMARY = "primary"
    UPSELL = "upsell"
    RECURRING = "recurring"
    ADJUSTMENT = "adjustment"


class PaymentMethod(str, Enum):
    PIX = "pix"
    CREDIT_CARD = "credit_card"
    BOLETO = "boleto"
    OTHER = "other"


class Platform(str, Enum):
    LASTLINK = "lastlink"
    PIX = "pix"
    MERCADO_PAGO = "mercado_pago"
    MANUAL = "manual"
    OTHER = "other"


class IntegrationProvider(str, Enum):
    LASTLINK = "lastlink"
    CORA = "cora"
    MERCADO_PAGO = "mercado_pago"


class IntegrationMode(str, Enum):
    MANUAL = "manual"
    WEBHOOK = "webhook"
    API = "api"


class IntegrationStatus(str, Enum):
    DISCONNECTED = "disconnected"
    READY = "ready"
    ERROR = "error"
    STAGED = "staged"


class SubscriptionCycle(str, Enum):
    MONTHLY = "monthly"
    ANNUAL = "annual"
    CUSTOM = "custom"


class SyncOperation(str, Enum):
    UPSERT = "upsert"
    DELETE = "delete"


class ConflictStatus(str, Enum):
    OPEN = "open"
    RESOLVED = "resolved"

