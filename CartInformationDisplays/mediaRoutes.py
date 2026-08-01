"""
HTTP endpoints for uploading and managing local video on the pit cart Pi.

The upload endpoint takes a raw streamed body (Content-Type: video/mp4),
not multipart/form-data. That sidesteps two problems with Starlette's
multipart handling for large files: it spools to a SpooledTemporaryFile
and then copies it again, which is brutal for a multi-gigabyte file on Pi
storage, and it would pull in python-multipart as a new dependency for no
real benefit here — the small amount of metadata (name/quality/duration/
width/height) fits fine in query params.
"""

import asyncio
import logging
import os
import time

from fastapi import APIRouter, HTTPException, Request
from starlette.responses import JSONResponse

from mediaLibrary import (
    FILES_DIR,
    deleteMedia,
    freeBytes,
    incomingPath,
    listMedia,
    newMediaId,
    readMeta,
    writeMeta,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/media")

# Refuse an upload that would leave less than this much free space, so the
# Pi never runs itself out of disk. Independent of the 48h/library-size
# janitor, which only cleans up after the fact.
RESERVE_BYTES = 2 * 1024 * 1024 * 1024  # 2 GB


@router.post("/upload")
async def uploadMedia(
    request: Request,
    name: str = "video",
    quality: str = "1080p",
    duration: float = 0,
    width: int = 0,
    height: int = 0,
):
    expected = int(request.headers.get("content-length") or 0)
    if expected and freeBytes() < expected + RESERVE_BYTES:
        raise HTTPException(status_code=507, detail="Not enough free space on the Pi")

    mediaId = newMediaId()
    partPath = incomingPath(mediaId)
    written = 0

    try:
        with open(partPath, "wb") as f:
            async for chunk in request.stream():
                if not chunk:
                    continue
                written += len(chunk)
                # Hop the actual disk write off the event loop. Without this,
                # a multi-GB write on Pi storage blocks in bursts and stalls
                # websocket pings + both cart displays mid-upload.
                await asyncio.to_thread(f.write, chunk)
    except Exception as e:
        logger.error(f"Upload failed for {mediaId}: {e}", exc_info=True)
        try:
            os.remove(partPath)
        except FileNotFoundError:
            pass
        raise HTTPException(status_code=500, detail="Upload failed") from e

    if written == 0:
        try:
            os.remove(partPath)
        except FileNotFoundError:
            pass
        raise HTTPException(status_code=400, detail="Empty upload body")

    finalPath = os.path.join(FILES_DIR, f"{mediaId}.mp4")
    # Same filesystem (both under media/) -> atomic rename. A partially
    # written file is never visible under files/, so /media/<id>.mp4 can
    # never be fetched truncated.
    os.replace(partPath, finalPath)

    meta = {
        "name": name,
        "quality": quality,
        "duration": duration,
        "width": width,
        "height": height,
        "size": written,
        "uploadedAt": time.time(),
    }
    writeMeta(mediaId, meta)

    # Import here (not at module scope) to avoid a circular import:
    # communicationBus is what routes controller messages to this module's
    # sibling functions, and main.py wires both together at startup.
    from communicationBus import communicationBus
    await communicationBus.pushLibrary()

    return JSONResponse(status_code=201, content={
        "id": mediaId,
        "url": f"/media/{mediaId}.mp4",
        **{k: v for k, v in meta.items() if k != "uploadedAt"},
        "uploadedAt": meta["uploadedAt"],
    })


@router.get("")
async def listMediaRoute():
    return listMedia()


@router.delete("/{mediaId}")
async def deleteMediaRoute(mediaId: str):
    meta = readMeta(mediaId)
    if meta is None:
        raise HTTPException(status_code=404, detail="Not found")
    deleteMedia(mediaId)

    from communicationBus import communicationBus
    await communicationBus.pushLibrary()

    return {"deleted": True}
