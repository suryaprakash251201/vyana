"""
Google Tasks API Routes
Replaces local task storage with Google Tasks integration
"""
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import List, Optional
from app.services import google_tasks_service as gts

router = APIRouter()


class TaskListResponse(BaseModel):
    id: str
    title: str
    updated: Optional[str] = None


class TaskResponse(BaseModel):
    id: str
    title: str
    notes: Optional[str] = None
    due: Optional[str] = None
    status: str
    is_completed: bool
    completed: Optional[str] = None
    parent: Optional[str] = None
    position: Optional[str] = None
    updated: Optional[str] = None


class CreateTaskRequest(BaseModel):
    title: str
    notes: Optional[str] = None
    due_date: Optional[str] = None  # YYYY-MM-DD format
    task_list_id: Optional[str] = '@default'
    parent: Optional[str] = None  # Parent task ID for subtasks


class UpdateTaskRequest(BaseModel):
    task_id: str
    task_list_id: Optional[str] = '@default'
    title: Optional[str] = None
    notes: Optional[str] = None
    due_date: Optional[str] = None


class CompleteTaskRequest(BaseModel):
    task_id: str
    task_list_id: Optional[str] = '@default'


class DeleteTaskRequest(BaseModel):
    task_id: str
    task_list_id: Optional[str] = '@default'


@router.get("/lists", response_model=List[TaskListResponse])
def get_task_lists():
    """Get all task lists"""
    try:
        return gts.list_task_lists()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/list")
def list_tasks(
    task_list_id: str = Query(default='@default'),
    include_completed: bool = Query(default=False),
    max_results: int = Query(default=100)
):
    """List tasks from a task list"""
    try:
        tasks = gts.list_tasks(task_list_id, include_completed, max_results)
        return tasks
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/get/{task_id}")
def get_task(task_id: str, task_list_id: str = Query(default='@default')):
    """Get a specific task"""
    try:
        return gts.get_task(task_list_id, task_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/create")
def create_task(req: CreateTaskRequest):
    """Create a new task"""
    try:
        return gts.create_task(
            title=req.title,
            task_list_id=req.task_list_id or '@default',
            notes=req.notes,
            due=req.due_date,
            parent=req.parent
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/update")
def update_task(req: UpdateTaskRequest):
    """Update a task"""
    try:
        return gts.update_task(
            task_id=req.task_id,
            task_list_id=req.task_list_id or '@default',
            title=req.title,
            notes=req.notes,
            due=req.due_date
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/complete")
def complete_task(req: CompleteTaskRequest):
    """Mark a task as completed"""
    try:
        result = gts.complete_task(req.task_id, req.task_list_id or '@default')
        return {"status": "success", "task": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/uncomplete")
def uncomplete_task(req: CompleteTaskRequest):
    """Mark a task as not completed"""
    try:
        result = gts.uncomplete_task(req.task_id, req.task_list_id or '@default')
        return {"status": "success", "task": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/delete")
def delete_task(req: DeleteTaskRequest):
    """Delete a task"""
    try:
        gts.delete_task(req.task_id, req.task_list_id or '@default')
        return {"status": "success", "task_id": req.task_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/clear-completed")
def clear_completed(task_list_id: str = '@default'):
    """Clear all completed tasks from a task list"""
    try:
        gts.clear_completed(task_list_id)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
