"""WebSocket companion server for streaming simulation and receiving commands from iOS app or CLI."""

import asyncio
import json
import logging
from typing import Set, Optional
import websockets
from ..protocol.messages import ProtocolMessage, MessageType, HelloPayload, AckPayload, ErrorPayload
from ..protocol.models import PROTOCOL_VERSION, SimulationTelemetry

logger = logging.getLogger(__name__)


class CompanionServer:
    """Async WebSocket server synchronizing PC controller and iOS app."""

    def __init__(self, host: str = "0.0.0.0", port: int = 8765):
        self.host = host
        self.port = port
        self.connected_clients: Set[websockets.WebSocketServerProtocol] = set()
        self.server: Optional[websockets.WebSocketServer] = None
        self._running = False

    async def start(self):
        self._running = True
        self.server = await websockets.serve(self._handle_client, self.host, self.port)
        logger.info(f"Companion Server listening on ws://{self.host}:{self.port}")

    async def stop(self):
        self._running = False
        if self.server:
            self.server.close()
            await self.server.wait_closed()
        for client in list(self.connected_clients):
            await client.close()
        self.connected_clients.clear()

    async def broadcast_telemetry(self, telemetry: SimulationTelemetry):
        msg = ProtocolMessage(
            protocol_version=PROTOCOL_VERSION,
            type=MessageType.STATE,
            payload=telemetry.model_dump(),
        )
        await self.broadcast_message(msg)

    async def broadcast_message(self, message: ProtocolMessage):
        if not self.connected_clients:
            return
        payload_str = message.model_dump_json()
        await asyncio.gather(
            *[client.send(payload_str) for client in self.connected_clients],
            return_exceptions=True,
        )

    async def _handle_client(self, websocket: websockets.WebSocketServerProtocol, path: str):
        self.connected_clients.add(websocket)
        logger.info(f"Client connected: {websocket.remote_address}")
        try:
            async for raw_msg in websocket:
                try:
                    data = json.loads(raw_msg)
                    msg = ProtocolMessage(**data)
                    await self._process_message(websocket, msg)
                except Exception as e:
                    err_msg = ProtocolMessage(
                        protocol_version=PROTOCOL_VERSION,
                        type=MessageType.ERROR,
                        payload=ErrorPayload(code="BAD_REQUEST", message=str(e)).model_dump(),
                    )
                    await websocket.send(err_msg.model_dump_json())
        except websockets.exceptions.ConnectionClosed:
            pass
        finally:
            self.connected_clients.discard(websocket)
            logger.info(f"Client disconnected: {websocket.remote_address}")

    async def _process_message(self, websocket: websockets.WebSocketServerProtocol, msg: ProtocolMessage):
        if msg.type == MessageType.HELLO:
            ack = ProtocolMessage(
                protocol_version=PROTOCOL_VERSION,
                type=MessageType.HELLO_ACK,
                payload=AckPayload(reply_to_id=msg.id, status="OK", message="Handshake established").model_dump(),
            )
            await websocket.send(ack.model_dump_json())
        elif msg.type == MessageType.HEARTBEAT:
            ack = ProtocolMessage(
                protocol_version=PROTOCOL_VERSION,
                type=MessageType.ACK,
                payload=AckPayload(reply_to_id=msg.id, status="OK").model_dump(),
            )
            await websocket.send(ack.model_dump_json())
