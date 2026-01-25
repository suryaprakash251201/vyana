"""
Google Tasks API Service
Provides integration with Google Tasks for task management
"""
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from app.services.google_oauth import OAuthService
from typing import Optional, List
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

oauth_service = OAuthService()


def get_tasks_service():
    """Get authenticated Google Tasks service"""
    creds = oauth_service.get_credentials()
    if not creds:
        raise Exception("Not authenticated with Google. Please authenticate first.")
    return build('tasks', 'v1', credentials=creds)


def list_task_lists() -> List[dict]:
    """List all task lists for the user"""
    try:
        service = get_tasks_service()
        results = service.tasklists().list().execute()
        task_lists = results.get('items', [])
        return [
            {
                'id': tl.get('id'),
                'title': tl.get('title'),
                'updated': tl.get('updated'),
            }
            for tl in task_lists
        ]
    except HttpError as e:
        logger.error(f"Error listing task lists: {e}")
        raise Exception(f"Failed to list task lists: {e}")


def list_tasks(task_list_id: str = '@default', show_completed: bool = False, max_results: int = 100) -> List[dict]:
    """
    List tasks from a specific task list
    
    Args:
        task_list_id: The task list ID (use '@default' for primary list)
        show_completed: Whether to include completed tasks
        max_results: Maximum number of tasks to return
    """
    try:
        service = get_tasks_service()
        results = service.tasks().list(
            tasklist=task_list_id,
            showCompleted=show_completed,
            showHidden=show_completed,
            maxResults=max_results
        ).execute()
        
        tasks = results.get('items', [])
        return [
            {
                'id': task.get('id'),
                'title': task.get('title', ''),
                'notes': task.get('notes', ''),
                'due': task.get('due'),  # RFC 3339 date string
                'status': task.get('status'),  # 'needsAction' or 'completed'
                'is_completed': task.get('status') == 'completed',
                'completed': task.get('completed'),  # Completion date
                'parent': task.get('parent'),  # Parent task ID for subtasks
                'position': task.get('position'),
                'updated': task.get('updated'),
                'links': task.get('links', []),
            }
            for task in tasks
        ]
    except HttpError as e:
        logger.error(f"Error listing tasks: {e}")
        raise Exception(f"Failed to list tasks: {e}")


def get_task(task_list_id: str, task_id: str) -> dict:
    """Get a specific task"""
    try:
        service = get_tasks_service()
        task = service.tasks().get(tasklist=task_list_id, task=task_id).execute()
        return {
            'id': task.get('id'),
            'title': task.get('title', ''),
            'notes': task.get('notes', ''),
            'due': task.get('due'),
            'status': task.get('status'),
            'is_completed': task.get('status') == 'completed',
            'completed': task.get('completed'),
            'parent': task.get('parent'),
            'position': task.get('position'),
            'updated': task.get('updated'),
            'links': task.get('links', []),
        }
    except HttpError as e:
        logger.error(f"Error getting task: {e}")
        raise Exception(f"Failed to get task: {e}")


def create_task(
    title: str,
    task_list_id: str = '@default',
    notes: Optional[str] = None,
    due: Optional[str] = None,  # ISO date string YYYY-MM-DD
    parent: Optional[str] = None,  # Parent task ID for subtasks
) -> dict:
    """
    Create a new task
    
    Args:
        title: Task title
        task_list_id: Task list ID
        notes: Task notes/description
        due: Due date in YYYY-MM-DD format
        parent: Parent task ID for creating subtasks
    """
    try:
        service = get_tasks_service()
        
        task_body = {
            'title': title,
            'status': 'needsAction',
        }
        
        if notes:
            task_body['notes'] = notes
            
        if due:
            # Google Tasks API expects RFC 3339 date format
            task_body['due'] = f"{due}T00:00:00.000Z"
        
        task = service.tasks().insert(
            tasklist=task_list_id,
            body=task_body,
            parent=parent
        ).execute()
        
        return {
            'id': task.get('id'),
            'title': task.get('title', ''),
            'notes': task.get('notes', ''),
            'due': task.get('due'),
            'status': task.get('status'),
            'is_completed': False,
            'updated': task.get('updated'),
        }
    except HttpError as e:
        logger.error(f"Error creating task: {e}")
        raise Exception(f"Failed to create task: {e}")


def update_task(
    task_id: str,
    task_list_id: str = '@default',
    title: Optional[str] = None,
    notes: Optional[str] = None,
    due: Optional[str] = None,
    status: Optional[str] = None,  # 'needsAction' or 'completed'
) -> dict:
    """
    Update an existing task
    
    Args:
        task_id: Task ID to update
        task_list_id: Task list ID
        title: New title (optional)
        notes: New notes (optional)
        due: New due date in YYYY-MM-DD format (optional)
        status: New status - 'needsAction' or 'completed' (optional)
    """
    try:
        service = get_tasks_service()
        
        # Get current task
        task = service.tasks().get(tasklist=task_list_id, task=task_id).execute()
        
        # Update fields
        if title is not None:
            task['title'] = title
        if notes is not None:
            task['notes'] = notes
        if due is not None:
            task['due'] = f"{due}T00:00:00.000Z"
        if status is not None:
            task['status'] = status
        
        updated = service.tasks().update(
            tasklist=task_list_id,
            task=task_id,
            body=task
        ).execute()
        
        return {
            'id': updated.get('id'),
            'title': updated.get('title', ''),
            'notes': updated.get('notes', ''),
            'due': updated.get('due'),
            'status': updated.get('status'),
            'is_completed': updated.get('status') == 'completed',
            'updated': updated.get('updated'),
        }
    except HttpError as e:
        logger.error(f"Error updating task: {e}")
        raise Exception(f"Failed to update task: {e}")


def complete_task(task_id: str, task_list_id: str = '@default') -> dict:
    """Mark a task as completed"""
    return update_task(task_id, task_list_id, status='completed')


def uncomplete_task(task_id: str, task_list_id: str = '@default') -> dict:
    """Mark a task as not completed"""
    return update_task(task_id, task_list_id, status='needsAction')


def delete_task(task_id: str, task_list_id: str = '@default') -> bool:
    """Delete a task"""
    try:
        service = get_tasks_service()
        service.tasks().delete(tasklist=task_list_id, task=task_id).execute()
        return True
    except HttpError as e:
        logger.error(f"Error deleting task: {e}")
        raise Exception(f"Failed to delete task: {e}")


def move_task(
    task_id: str,
    task_list_id: str = '@default',
    parent: Optional[str] = None,
    previous: Optional[str] = None,
) -> dict:
    """
    Move a task to a different position
    
    Args:
        task_id: Task ID to move
        task_list_id: Task list ID
        parent: New parent task ID (for subtasks)
        previous: Previous sibling task ID (for ordering)
    """
    try:
        service = get_tasks_service()
        
        task = service.tasks().move(
            tasklist=task_list_id,
            task=task_id,
            parent=parent,
            previous=previous
        ).execute()
        
        return {
            'id': task.get('id'),
            'title': task.get('title', ''),
            'parent': task.get('parent'),
            'position': task.get('position'),
        }
    except HttpError as e:
        logger.error(f"Error moving task: {e}")
        raise Exception(f"Failed to move task: {e}")


def clear_completed(task_list_id: str = '@default') -> bool:
    """Clear all completed tasks from a task list"""
    try:
        service = get_tasks_service()
        service.tasks().clear(tasklist=task_list_id).execute()
        return True
    except HttpError as e:
        logger.error(f"Error clearing completed tasks: {e}")
        raise Exception(f"Failed to clear completed tasks: {e}")
