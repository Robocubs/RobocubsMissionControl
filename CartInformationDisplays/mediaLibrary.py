"""
Local-video storage layer for the pit cart screens.

Pure storage: no FastAPI imports here, so this can be exercised directly
with a plain python3 interpreter (see the Phase 1 curl/manual tests).

Layout, all under MEDIA_ROOT:
    incoming/<id>.part   in-progress upload, invisible to everything else
    files/<id>.mp4       finished file, served statically at /media
    meta/<id>.json       sidecar metadata (name, quality, duration, ...)

A sidecar-per-file design (rather than one index.json) avoids read-modify-
write races between a concurrent upload, a delete, and the janitor sweep —
each of those touches only the files for the id it cares about. The index
is just "whatever is in meta/", so it's trivially rebuildable by scanning
the directory; nothing can get permanently out of sync with disk.

IDs are never derived from the client-supplied filename. That's the
path-traversal guard: the display name is free text that only ever lives
inside a sidecar's JSON body, never in a path.
"""

import json
import logging
import os
import shutil
import time
import uuid
from typing import Any, Dict, List, Optional, Set

logger = logging.getLogger(__name__)

_CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
MEDIA_ROOT = os.path.join(_CURRENT_DIR, "media")
INCOMING_DIR = os.path.join(MEDIA_ROOT, "incoming")
FILES_DIR = os.path.join(MEDIA_ROOT, "files")
META_DIR = os.path.join(MEDIA_ROOT, "meta")


def ensureDirectories() -> None:
    """Create the media directory tree if it's missing.

    media/ is gitignored, so it will not exist on a fresh checkout. This
    must run before StaticFiles(directory=FILES_DIR) is mounted in
    main.py: FastAPI raises at mount time if the directory is absent, and
    under systemd's Restart=always that's a crash loop with no websocket
    left to recover through.
    """
    for d in (MEDIA_ROOT, INCOMING_DIR, FILES_DIR, META_DIR):
        os.makedirs(d, exist_ok=True)


def newMediaId() -> str:
    # Sortable by creation time, collision-free, and carries no user input.
    return f"{int(time.time())}-{uuid.uuid4().hex[:8]}"


def _metaPath(mediaId: str) -> str:
    return os.path.join(META_DIR, f"{mediaId}.json")


def _filePath(mediaId: str) -> str:
    return os.path.join(FILES_DIR, f"{mediaId}.mp4")


def incomingPath(mediaId: str) -> str:
    return os.path.join(INCOMING_DIR, f"{mediaId}.part")


def writeMeta(mediaId: str, meta: Dict[str, Any]) -> None:
    with open(_metaPath(mediaId), "w") as f:
        json.dump(meta, f)


def readMeta(mediaId: Optional[str]) -> Optional[Dict[str, Any]]:
    if not mediaId:
        return None
    # Guard against a mediaId that isn't a plain id (e.g. containing a path
    # separator) reaching the filesystem, however it got here.
    if "/" in mediaId or "\\" in mediaId or mediaId in (".", ".."):
        return None
    path = _metaPath(mediaId)
    if not os.path.isfile(path):
        return None
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        logger.warning(f"Failed to read metadata for {mediaId}: {e}")
        return None


def listMedia() -> List[Dict[str, Any]]:
    """List all media that has both a sidecar and a finished file.

    An entry whose files/<id>.mp4 is missing (upload still in progress, or
    got interrupted) is silently skipped rather than surfaced as broken.
    """
    if not os.path.isdir(META_DIR):
        return []
    items = []
    for name in os.listdir(META_DIR):
        if not name.endswith(".json"):
            continue
        mediaId = name[: -len(".json")]
        meta = readMeta(mediaId)
        if meta is None:
            continue
        if not os.path.isfile(_filePath(mediaId)):
            continue
        items.append({
            "id": mediaId,
            "name": meta.get("name", mediaId),
            "quality": meta.get("quality", "unknown"),
            "duration": meta.get("duration", 0),
            "size": meta.get("size", 0),
            "width": meta.get("width", 0),
            "height": meta.get("height", 0),
            "uploadedAt": meta.get("uploadedAt", 0),
        })
    items.sort(key=lambda m: m["uploadedAt"], reverse=True)
    return items


def deleteMedia(mediaId: Optional[str]) -> bool:
    if not mediaId:
        return False
    meta = readMeta(mediaId)
    if meta is None:
        return False
    removed = False
    for path in (_filePath(mediaId), _metaPath(mediaId)):
        try:
            os.remove(path)
            removed = True
        except FileNotFoundError:
            pass
    return removed


def freeBytes() -> int:
    return shutil.disk_usage(MEDIA_ROOT).free


def totalLibraryBytes() -> int:
    return sum(m.get("size", 0) for m in listMedia())


def pruneExpired(maxAgeSeconds: float, protectedIds: Optional[Set[str]] = None,
                  maxLibraryBytes: Optional[int] = None) -> List[str]:
    """Delete media older than maxAgeSeconds, never touching a protected id.

    protectedIds is the set of media currently selected on either cart —
    deleting the clip that's on screen mid-match is worse than keeping a
    file a little past its 48h window.

    If maxLibraryBytes is given, also evicts oldest-first (still skipping
    protected ids) until the library fits, independent of age. A full SD
    card takes the whole server down, not just uploads, so this is a
    second independent guard rather than a replacement for the age check.
    """
    protectedIds = protectedIds or set()
    now = time.time()
    removed: List[str] = []

    for item in listMedia():
        mediaId = item["id"]
        if mediaId in protectedIds:
            continue
        age = now - item.get("uploadedAt", now)
        if age > maxAgeSeconds:
            if deleteMedia(mediaId):
                removed.append(mediaId)

    if maxLibraryBytes is not None:
        remaining = [m for m in listMedia() if m["id"] not in protectedIds]
        remaining.sort(key=lambda m: m["uploadedAt"])  # oldest first
        total = totalLibraryBytes()
        for item in remaining:
            if total <= maxLibraryBytes:
                break
            if deleteMedia(item["id"]):
                removed.append(item["id"])
                total -= item.get("size", 0)

    return removed
