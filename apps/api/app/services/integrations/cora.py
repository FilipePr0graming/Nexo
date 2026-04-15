from __future__ import annotations

from dataclasses import dataclass


@dataclass(slots=True)
class CoraDirectAuthRequest:
    token_url: str
    requires_client_certificate: bool
    requires_private_key: bool
    requires_client_id: bool


def build_cora_direct_auth_request(stage: bool = True) -> CoraDirectAuthRequest:
    base_url = "https://matls-clients.api.stage.cora.com.br/token" if stage else "https://matls-clients.api.cora.com.br/token"
    return CoraDirectAuthRequest(
        token_url=base_url,
        requires_client_certificate=True,
        requires_private_key=True,
        requires_client_id=True,
    )

