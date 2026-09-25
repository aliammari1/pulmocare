"""Behavioral tests for the patients service."""

import pytest

pytestmark = pytest.mark.asyncio


def _override_user(app, dependency, user):
    app.dependency_overrides[dependency] = lambda: user


async def test_health(client):
    resp = await client.get("/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "healthy"
    assert body["service"] == "patients-service"
    assert body["dependencies"]["redis"] == "UP"


async def test_liveness_probe(client):
    resp = await client.get("/health/live")
    assert resp.status_code == 200
    assert resp.json()["status"] == "alive"


async def test_openapi_lists_patient_routes(client):
    resp = await client.get("/openapi.json")
    assert resp.status_code == 200
    paths = resp.json()["paths"]
    assert "/api/patients/{patient_id}" in paths
    assert "/api/patients/profile" in paths
    assert "/api/patients/medical-history" in paths
    assert "/api/patients/prescriptions" in paths


async def test_get_patient_requires_auth(client):
    resp = await client.get("/api/patients/some-id")
    assert resp.status_code in (401, 403)


async def test_profile_update_requires_auth(client):
    resp = await client.put("/api/patients/profile", json={"name": "x"})
    assert resp.status_code in (401, 403)


async def test_patient_cannot_access_another_patient(client, app):
    import routes.patients_routes as routes

    _override_user(
        app,
        routes.get_current_patient,
        {"user_id": "patient-1", "roles": ["patient"], "token": "test-token"},
    )
    try:
        resp = await client.get("/api/patients/patient-2")
        assert resp.status_code == 403
    finally:
        app.dependency_overrides.clear()


async def test_provider_can_access_patient(client, app, monkeypatch):
    import routes.patients_routes as routes

    async def fake_get_patient_by_id(patient_id, token):
        assert patient_id == "patient-2"
        assert token == "test-token"
        return {"id": patient_id, "email": "patient@example.test"}

    monkeypatch.setattr(routes, "get_patient_by_id", fake_get_patient_by_id)
    _override_user(
        app,
        routes.get_current_patient,
        {"user_id": "doctor-1", "roles": ["doctor"], "token": "test-token"},
    )
    try:
        resp = await client.get("/api/patients/patient-2")
        assert resp.status_code == 200
        assert resp.json()["id"] == "patient-2"
    finally:
        app.dependency_overrides.clear()


async def test_request_appointment_rejects_different_patient(client, app):
    import routes.patients_routes as routes

    _override_user(
        app,
        routes.get_current_patient,
        {"user_id": "patient-1", "roles": ["patient"], "token": "test-token"},
    )
    try:
        resp = await client.post(
            "/api/patients/request-appointment",
            params={
                "doctor_id": "doctor-1",
                "patient_id": "patient-2",
                "requested_time": "2026-10-01T09:00:00Z",
            },
        )
        assert resp.status_code == 403
    finally:
        app.dependency_overrides.clear()


async def test_request_appointment_success(client, app, monkeypatch):
    import routes.patients_routes as routes

    async def fake_get_patient_by_id(patient_id, token):
        return {"id": patient_id}

    async def fake_get_user_info(patient_id, token):
        return {"attributes": {"appointment_requests": []}}

    async def fake_update_user_attributes(patient_id, attributes, token):
        assert attributes["appointment_requests"]
        return {"updated": True}

    monkeypatch.setattr(routes, "get_patient_by_id", fake_get_patient_by_id)
    monkeypatch.setattr(routes, "get_user_info", fake_get_user_info)
    monkeypatch.setattr(routes, "update_user_attributes", fake_update_user_attributes)
    monkeypatch.setattr(
        routes.rabbitmq_client,
        "publish_appointment_request",
        lambda **kwargs: True,
    )
    _override_user(
        app,
        routes.get_current_patient,
        {"user_id": "patient-1", "roles": ["patient"], "token": "test-token"},
    )
    try:
        resp = await client.post(
            "/api/patients/request-appointment",
            params={
                "doctor_id": "doctor-1",
                "requested_time": "2026-10-01T09:00:00Z",
                "reason": "follow-up",
            },
        )
        assert resp.status_code == 200
        assert "Request ID:" in resp.json()["message"]
    finally:
        app.dependency_overrides.clear()


async def test_medical_history_static_route(client, app, monkeypatch):
    import routes.patients_routes as routes

    monkeypatch.setattr(
        routes.rabbitmq_client,
        "request_patient_prescriptions",
        lambda patient_id: [{"id": "rx-1"}],
    )
    monkeypatch.setattr(
        routes.rabbitmq_client,
        "request_patient_medical_records",
        lambda patient_id: [{"id": "record-1"}],
    )
    monkeypatch.setattr(
        routes.rabbitmq_client,
        "request_patient_radiology_reports",
        lambda patient_id: [{"id": "report-1"}],
    )

    async def fake_get_user_info(patient_id, token):
        return {
            "attributes": {
                "allergies": ["dust"],
                "medical_history": ["asthma"],
            }
        }

    monkeypatch.setattr(routes, "get_user_info", fake_get_user_info)
    _override_user(
        app,
        routes.get_current_patient,
        {"user_id": "patient-1", "roles": ["patient"], "token": "test-token"},
    )
    try:
        resp = await client.get("/api/patients/medical-history")
        assert resp.status_code == 200
        body = resp.json()
        assert body["prescriptions"] == [{"id": "rx-1"}]
        assert body["allergies"] == ["dust"]
        assert body["medical_history_items"] == ["asthma"]
    finally:
        app.dependency_overrides.clear()


async def test_prescriptions_static_route(client, app, monkeypatch):
    import routes.patients_routes as routes

    monkeypatch.setattr(
        routes.rabbitmq_client,
        "request_patient_prescriptions",
        lambda patient_id: [{"id": "rx-1"}],
    )
    _override_user(
        app,
        routes.get_current_patient,
        {"user_id": "patient-1", "roles": ["patient"], "token": "test-token"},
    )
    try:
        resp = await client.get("/api/patients/prescriptions")
        assert resp.status_code == 200
        assert resp.json() == {"prescriptions": [{"id": "rx-1"}]}
    finally:
        app.dependency_overrides.clear()
