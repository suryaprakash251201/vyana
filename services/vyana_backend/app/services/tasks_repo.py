import sqlite3
import os
from typing import List, Optional, Dict
import datetime
from pydantic import BaseModel

# Use /app/data for Docker, or current dir for local dev
DATA_DIR = os.environ.get("DATA_DIR", ".")
os.makedirs(DATA_DIR, exist_ok=True)
DB_PATH = os.path.join(DATA_DIR, "vyana.db")

class TaskItem(BaseModel):
    id: int
    title: str
    is_completed: bool
    created_at: str
    due_date: Optional[str] = None

class AbstractTasksRepo:
    def create_table(self):
        pass
    def add_task(self, title: str, due_date: Optional[str] = None) -> TaskItem:
        pass
    def list_tasks(self, include_completed: bool = False) -> List[TaskItem]:
        pass
    def complete_task(self, task_id: int) -> bool:
        pass
    def get_task(self, task_id: int) -> Optional[TaskItem]:
        pass

class SqliteTasksRepo(AbstractTasksRepo):
    def __init__(self, db_path=DB_PATH):
        self.db_path = db_path
        self.create_table()

    def _get_conn(self):
        return sqlite3.connect(self.db_path)

    def create_table(self):
        with self._get_conn() as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS tasks (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    title TEXT NOT NULL,
                    is_completed BOOLEAN DEFAULT 0,
                    created_at TEXT,
                    due_date TEXT
                )
            """)

    def add_task(self, title: str, due_date: Optional[str] = None) -> TaskItem:
        now = datetime.datetime.now().isoformat()
        with self._get_conn() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO tasks (title, is_completed, created_at, due_date) VALUES (?, ?, ?, ?)",
                (title, False, now, due_date)
            )
            task_id = cursor.lastrowid
            conn.commit()
            return TaskItem(id=task_id, title=title, is_completed=False, created_at=now, due_date=due_date)

    def list_tasks(self, include_completed: bool = False) -> List[TaskItem]:
        query = "SELECT id, title, is_completed, created_at, due_date FROM tasks"
        if not include_completed:
            query += " WHERE is_completed = 0"
        
        with self._get_conn() as conn:
            cursor = conn.cursor()
            rows = cursor.execute(query).fetchall()
            return [
                TaskItem(
                    id=row[0],
                    title=row[1],
                    is_completed=bool(row[2]),
                    created_at=row[3],
                    due_date=row[4]
                ) for row in rows
            ]

    def complete_task(self, task_id: int) -> bool:
        with self._get_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("UPDATE tasks SET is_completed = 1 WHERE id = ?", (task_id,))
            conn.commit()
            return cursor.rowcount > 0
    
    def get_task(self, task_id: int) -> Optional[TaskItem]:
        with self._get_conn() as conn:
            cursor = conn.cursor()
            row = cursor.execute(
                "SELECT id, title, is_completed, created_at, due_date FROM tasks WHERE id = ?",
                (task_id,)
            ).fetchone()
            if not row:
                return None
            return TaskItem(
                id=row[0],
                title=row[1],
                is_completed=bool(row[2]),
                created_at=row[3],
                due_date=row[4]
            )

    def update_task(self, task_id: int, title: str = None, due_date: str = None) -> bool:
        """Update task title and/or due date"""
        if not title and not due_date:
            return False
        
        updates = []
        params = []
        
        if title:
            updates.append("title = ?")
            params.append(title)
        if due_date:
            updates.append("due_date = ?")
            params.append(due_date)
        
        params.append(task_id)
        query = f"UPDATE tasks SET {', '.join(updates)} WHERE id = ?"
        
        with self._get_conn() as conn:
            cursor = conn.cursor()
            cursor.execute(query, params)
            conn.commit()
            return cursor.rowcount > 0
    
    def delete_task(self, task_id: int) -> bool:
        """Delete a task"""
        with self._get_conn() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM tasks WHERE id = ?", (task_id,))
            conn.commit()
            return cursor.rowcount > 0
    
    def search_tasks(self, query: str) -> List[TaskItem]:
        """Search tasks by title"""
        search_query = "SELECT id, title, is_completed, created_at, due_date FROM tasks WHERE title LIKE ? AND is_completed = 0"
        
        with self._get_conn() as conn:
            cursor = conn.cursor()
            rows = cursor.execute(search_query, (f"%{query}%",)).fetchall()
            return [
                TaskItem(
                    id=row[0],
                    title=row[1],
                    is_completed=bool(row[2]),
                    created_at=row[3],
                    due_date=row[4]
                ) for row in rows
            ]

tasks_repo = SqliteTasksRepo()
