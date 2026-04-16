import asyncio
import logging
import os
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)

HLS_DIR_L = "/tmp/hls_L"
HLS_DIR_R = "/tmp/hls_R"

class CommunicationBus:
    def __init__(self):
        self.cartL: Optional[Any] = None
        self.cartR: Optional[Any] = None
        self.missionController: Optional[Any] = None
        self.youtubeL: Optional[str] = None
        self.twitchL: Optional[str] = None
        self.youtubeR: Optional[str] = None
        self.twitchR: Optional[str] = None
        self.livestreamL: Optional[str] = "udp://239.255.0.0:1234"
        self.livestreamR: Optional[str] = "udp://239.255.0.0:1234"
        self.stateL: str = "localLivestream"
        self.stateR: str = "screensaver"
        self.matchCode: Optional[str] = None
        self._ffmpegL: Optional[asyncio.subprocess.Process] = None
        self._ffmpegR: Optional[asyncio.subprocess.Process] = None
        self._ffmpegL_lock: asyncio.Lock = asyncio.Lock()
        self._ffmpegR_lock: asyncio.Lock = asyncio.Lock()

    async def sendL(self, message: Dict[str, Any]):
        if self.cartL:
            await self.cartL.send_json(message)
            logger.info(f"Sent to CartL: {message}")
        else:
            logger.info("CartL not connected")

    async def sendR(self, message: Dict[str, Any]):
        if self.cartR:
            await self.cartR.send_json(message)
            logger.info(f"Sent to CartR: {message}")
        else:
            logger.info("CartR not connected")

    async def sendMissionController(self, message: Dict[str, Any]):
        if self.missionController:
            await self.missionController.send_json(message)
            logger.info(f"Sent to MissionController: {message}")
        else:
            logger.info("MissionController not connected")

    def _ffmpeg_cmd(self, stream_url: str, hls_dir: str) -> list[str]:
        return [
            "ffmpeg", "-y",
            "-i", stream_url,
            "-c:v", "libx264",
            "-preset", "ultrafast",
            "-tune", "zerolatency",
            "-pix_fmt", "yuv420p",
            "-g", "25",
            "-keyint_min", "25",
            "-sc_threshold", "0",
            "-f", "hls",
            "-hls_time", "1",
            "-hls_list_size", "3",
            "-hls_flags", "delete_segments+omit_endlist+independent_segments",
            "-hls_segment_filename", os.path.join(hls_dir, "seg%05d.ts"),
            "-hls_allow_cache", "0",
            os.path.join(hls_dir, "stream.m3u8"),
        ]

    async def _stop_ffmpeg(self, side: str) -> None:
        proc = self._ffmpegL if side == "L" else self._ffmpegR
        if proc is None:
            return
        try:
            proc.terminate()
            try:
                await asyncio.wait_for(proc.wait(), timeout=5.0)
            except asyncio.TimeoutError:
                proc.kill()
                await proc.wait()
        except ProcessLookupError:
            pass
        finally:
            if side == "L":
                self._ffmpegL = None
            else:
                self._ffmpegR = None
        logger.info(f"FFmpeg {side} stopped")

    async def _start_ffmpeg(self, side: str, stream_url: str) -> None:
        hls_dir = HLS_DIR_L if side == "L" else HLS_DIR_R
        lock = self._ffmpegL_lock if side == "L" else self._ffmpegR_lock
        async with lock:
            await self._stop_ffmpeg(side)
            for f in os.listdir(hls_dir):
                try:
                    os.remove(os.path.join(hls_dir, f))
                except OSError:
                    pass
            cmd = self._ffmpeg_cmd(stream_url, hls_dir)
            logger.info(f"Starting FFmpeg {side}: {' '.join(cmd)}")
            proc = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.DEVNULL,
                stderr=asyncio.subprocess.PIPE,
            )
            if side == "L":
                self._ffmpegL = proc
            else:
                self._ffmpegR = proc
            asyncio.create_task(self._watch_ffmpeg(proc, side, stream_url))

    async def _watch_ffmpeg(self, proc: asyncio.subprocess.Process, side: str, stream_url: str) -> None:
        if proc.stderr is not None:
            async for line in proc.stderr:
                logger.debug(f"FFmpeg {side}: {line.decode(errors='replace').rstrip()}")
        returncode = await proc.wait()
        logger.warning(f"FFmpeg {side} exited with code {returncode}")
        current = self._ffmpegL if side == "L" else self._ffmpegR
        if current is not proc:
            return
        if side == "L":
            self._ffmpegL = None
        else:
            self._ffmpegR = None
        if returncode != 0:
            send_fn = self.sendL if side == "L" else self.sendR
            await send_fn({"type": "livestreamError", "data": "Stream unavailable, retrying..."})
            await asyncio.sleep(5)
            current_url = self.livestreamL if side == "L" else self.livestreamR
            if current_url == stream_url:
                await self._start_ffmpeg(side, stream_url)

    async def recieveMissionController(self, data: Dict[str, Any]):
        try:
            msg_type = data.get("type")

            if msg_type == "state" or msg_type == "stateL" or msg_type == "stateR":
                state_value = data.get("data")
                if msg_type in ("state", "stateL"):
                    self.stateL = state_value
                    if state_value == "localLivestream" and self.livestreamL:
                        asyncio.create_task(self._start_ffmpeg("L", self.livestreamL))
                    elif state_value != "localLivestream":
                        asyncio.create_task(self._stop_ffmpeg("L"))
                if msg_type in ("state", "stateR"):
                    self.stateR = state_value
                    if state_value == "localLivestream" and self.livestreamR:
                        asyncio.create_task(self._start_ffmpeg("R", self.livestreamR))
                    elif state_value != "localLivestream":
                        asyncio.create_task(self._stop_ffmpeg("R"))
                await self.sendL(data)
                await self.sendR(data)
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "youtubeLUpdate":
                self.youtubeL = data.get("data")
                await self.sendL({"type": "youtubeUpdate", "data": data.get("data")})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "youtubeRUpdate":
                self.youtubeR = data.get("data")
                await self.sendR({"type": "youtubeUpdate", "data": data.get("data")})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "twitchLUpdate":
                self.twitchL = data.get("data")
                await self.sendL({"type": "twitchUpdate", "data": data.get("data")})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "twitchRUpdate":
                self.twitchR = data.get("data")
                await self.sendR({"type": "twitchUpdate", "data": data.get("data")})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "livestreamLUpdate":
                self.livestreamL = data.get("data")
                if self.livestreamL:
                    asyncio.create_task(self._start_ffmpeg("L", self.livestreamL))
                else:
                    asyncio.create_task(self._stop_ffmpeg("L"))
                await self.sendL({"type": "livestreamUpdate", "data": self.livestreamL})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "livestreamRUpdate":
                self.livestreamR = data.get("data")
                if self.livestreamR:
                    asyncio.create_task(self._start_ffmpeg("R", self.livestreamR))
                else:
                    asyncio.create_task(self._stop_ffmpeg("R"))
                await self.sendR({"type": "livestreamUpdate", "data": self.livestreamR})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "matchCode":
                self.matchCode = data.get("data")
                await self.sendMissionController({"type": "confirm", "data": "true"})
            else:
                logger.info(f"Unknown command type: {msg_type}")
                await self.sendMissionController({"type": "confirm", "data": "false"})
        except Exception as e:
            logger.error(f"Error handling command: {e}")
            await self.sendMissionController({"type": "confirm", "data": "false"})

# Global communication bus
communicationBus = CommunicationBus()
