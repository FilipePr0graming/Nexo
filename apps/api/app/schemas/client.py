from app.models.enums import BillingProfile, ClientStatus, Platform, ServiceStage
from app.schemas.common import ORMBaseModel, RecordMeta


class ClientBase(ORMBaseModel):
    name: str
    email: str | None = None
    phone: str | None = None
    notes: str | None = None
    lead_source: str | None = None
    sales_platform: Platform | None = None
    service_name: str | None = None
    related_group: str | None = None
    service_stage: ServiceStage = ServiceStage.LEAD
    status: ClientStatus = ClientStatus.LEAD
    billing_profile: BillingProfile = BillingProfile.ONE_OFF
    daniel_participation_default: bool = False


class ClientCreate(ClientBase):
    id: str | None = None


class ClientUpdate(ORMBaseModel):
    name: str | None = None
    email: str | None = None
    phone: str | None = None
    notes: str | None = None
    lead_source: str | None = None
    sales_platform: Platform | None = None
    service_name: str | None = None
    related_group: str | None = None
    service_stage: ServiceStage | None = None
    status: ClientStatus | None = None
    billing_profile: BillingProfile | None = None
    daniel_participation_default: bool | None = None


class ClientRead(ClientBase, RecordMeta):
    workspace_id: str

