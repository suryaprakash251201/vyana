from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from app.services.tasks_repo import tasks_repo, TaskItem

router = APIRouter()

class CreateTaskRequest(BaseModel):
    title: str
    due_date: Optional[str] = None

class CompleteTaskRequest(BaseModel):
    task_id: int

@router.get("/list", response_model=List[TaskItem])
def list_tasks(include_completed: bool = False):
    return tasks_repo.list_tasks(include_completed)

@router.post("/create", response_model=TaskItem)
def create_task(req: CreateTaskRequest):
    return tasks_repo.add_task(req.title, req.due_date)

@router.post("/complete")
def complete_task(req: CompleteTaskRequest):
    success = tasks_repo.complete_task(req.task_id)
    if not success:
        raise HTTPException(status_code=404, detail="Task not found")
    return {"status": "success", "task_id": req.task_id}

class UpdateTaskRequest(BaseModel):
    task_id: int
    title: Optional[str] = None
    due_date: Optional[str] = None

class DeleteTaskRequest(BaseModel):
    task_id: int

@router.post("/update")
def update_task(req: UpdateTaskRequest):
    success = tasks_repo.update_task(req.task_id, title=req.title, due_date=req.due_date)
    if not success:
        raise HTTPException(status_code=404, detail="Task not found or no changes made")
    return {"status": "success", "task_id": req.task_id}

@router.post("/delete")
def delete_task(req: DeleteTaskRequest):
    success = tasks_repo.delete_task(req.task_id)
    if not success:
        raise HTTPException(status_code=404, detail="Task not found")
    return {"status": "success", "task_id": req.task_id}
