from fastapi import APIRouter
from app.services.cache_service import cache_service

router = APIRouter()

@router.get("/health")
def health_check():
    return {"status": "ok", "version": "0.1.0"}


@router.get("/cache/stats")
async def cache_stats():
    """Get Redis cache statistics"""
    return await cache_service.get_stats()


@router.post("/cache/clear")
async def cache_clear(pattern: str = ""):
    """Clear cache keys matching pattern (admin only)"""
    if pattern:
        deleted = await cache_service.clear_pattern(pattern)
        return {"cleared": deleted, "pattern": pattern}
    else:
        # Clear all vyana keys
        deleted = await cache_service.clear_pattern("")
        return {"cleared": deleted, "pattern": "all"}
