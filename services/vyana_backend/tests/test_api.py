import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_health_check():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "version": "0.1.0"}

@pytest.mark.asyncio
async def test_tasks_flow():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # Create Task
        res = await ac.post("/tasks/create", json={"title": "Test Task", "due_date": "2026-01-01"})
        assert res.status_code == 200
        data = res.json()
        task_id = data["id"]
        assert data["title"] == "Test Task"
        assert data["is_completed"] is False

        # List Tasks
        res = await ac.get("/tasks/list")
        assert res.status_code == 200
        tasks = res.json()
        assert len(tasks) >= 1
        assert tasks[-1]["id"] == task_id

        # Complete Task
        res = await ac.post("/tasks/complete", json={"task_id": task_id})
        assert res.status_code == 200
        
        # Verify Completed
        res = await ac.get("/tasks/list") # Should be empty or not contain this one
        tasks = res.json()
        ids = [t["id"] for t in tasks]
        assert task_id not in ids
