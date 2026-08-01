import logging
import asyncio
from communicationBus import communicationBus
from mediaLibrary import pruneExpired
from tba import getMatches

logger = logging.getLogger(__name__)

async def matchUpdate():
    while True:
        try:
            if communicationBus.matchCode:
                matches = await getMatches(communicationBus.matchCode)
                if matches != []:
                    await communicationBus.sendMissionController({"type": "matchPackage", "data": matches})
        except Exception as e:
            logger.error(f"Error in matchUpdate iteration: {e}", exc_info=True)

        await asyncio.sleep(10)

# The Pi is a cache, not an archive — the originals stay in the iPad's
# Photos library, so anything older than this just gets swept.
MEDIA_MAX_AGE_SECONDS = 48 * 60 * 60
# A full SD card takes the whole server down, not just uploads, so this is
# a second, independent guard on top of the age-based sweep.
MEDIA_MAX_LIBRARY_BYTES = 24 * 1024 * 1024 * 1024  # 24 GB
MEDIA_JANITOR_INTERVAL_SECONDS = 10 * 60

async def mediaJanitor():
    # Run once immediately at startup, not just on the first 10-minute
    # tick: the Pi is powered off between events, so a wall-clock sweep on
    # boot is when most of the actual deleting happens.
    while True:
        try:
            # Never delete whatever's currently selected on either cart —
            # losing the clip that's on screen mid-match would be worse
            # than keeping a file a little past its 48h window.
            protected = {communicationBus.localVideoL, communicationBus.localVideoR} - {None}
            removed = pruneExpired(
                MEDIA_MAX_AGE_SECONDS,
                protectedIds=protected,
                maxLibraryBytes=MEDIA_MAX_LIBRARY_BYTES,
            )
            if removed:
                logger.info(f"Media janitor removed {len(removed)} video(s): {removed}")
                await communicationBus.pushLibrary()
        except Exception as e:
            logger.error(f"Error in mediaJanitor iteration: {e}", exc_info=True)

        await asyncio.sleep(MEDIA_JANITOR_INTERVAL_SECONDS)