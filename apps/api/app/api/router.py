from fastapi import APIRouter

from app.api.routes import backups, clients, dashboard, expenses, health, integrations, owner_draws, sales, subscriptions, sync

api_router = APIRouter()
api_router.include_router(health.router, tags=["health"])
api_router.include_router(clients.router, prefix="/clients", tags=["clients"])
api_router.include_router(sales.router, prefix="/sales", tags=["sales"])
api_router.include_router(expenses.router, prefix="/expenses", tags=["expenses"])
api_router.include_router(subscriptions.router, prefix="/subscriptions", tags=["subscriptions"])
api_router.include_router(owner_draws.router, prefix="/owner-draws", tags=["owner-draws"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])
api_router.include_router(sync.router, prefix="/sync", tags=["sync"])
api_router.include_router(backups.router, prefix="/backups", tags=["backups"])
api_router.include_router(integrations.router, prefix="/integrations", tags=["integrations"])

