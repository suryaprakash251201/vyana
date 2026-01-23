from fastapi import APIRouter
import psutil
import time
from datetime import timedelta

router = APIRouter()

start_time = time.time()

@router.get("/system")
async def get_system_stats():
    """
    Returns system monitoring metrics:
    - CPU Usage (per core and total)
    - Memory Usage
    - Disk Usage
    - Network Stats
    - Uptime
    """
    
    # CPU
    cpu_percent = psutil.cpu_percent(interval=None)
    cpu_per_cpu = psutil.cpu_percent(interval=None, percpu=True)
    
    # Memory
    mem = psutil.virtual_memory()
    memory_stats = {
        "total": mem.total,
        "available": mem.available,
        "used": mem.used,
        "percent": mem.percent
    }
    
    # Disk
    disk = psutil.disk_usage('/')
    disk_stats = {
        "total": disk.total,
        "used": disk.used,
        "free": disk.free,
        "percent": disk.percent
    }
    
    # Uptime
    uptime_seconds = time.time() - start_time
    uptime_str = str(timedelta(seconds=int(uptime_seconds)))
    
    # Net IO (bytes sent/recv)
    net = psutil.net_io_counters()
    net_stats = {
        "bytes_sent": net.bytes_sent,
        "bytes_recv": net.bytes_recv
    }

    return {
        "cpu": {
            "percent": cpu_percent,
            "cores": cpu_per_cpu
        },
        "memory": memory_stats,
        "disk": disk_stats,
        "network": net_stats,
        "uptime": uptime_str,
        "platform": "Windows" if psutil.WINDOWS else "Linux"
    }
