import { WebSocketServer, WebSocket } from "ws";
import { randomBytes } from "node:crypto";

type SignalMessage =
  | {
      kind: "session";
      type: "offer" | "answer";
      sdp: string;
    }
  | {
      kind: "ice";
      media: string;
      index: number;
      name: string;
    };

type ClientMessage =
  | { type: "create_room" }
  | { type: "join_room"; roomId: string }
  | { type: "signal"; roomId: string; signal: SignalMessage };

type ServerMessage =
  | { type: "room_created"; roomId: string }
  | { type: "room_joined"; roomId: string }
  | { type: "signal"; roomId: string; signal: SignalMessage }
  | { type: "error"; message: string };

type Room = {
  host?: WebSocket;
  client?: WebSocket;
};

const PORT = Number(process.env.PORT ?? 8080);
const wss = new WebSocketServer({ port: PORT });
const rooms = new Map<string, Room>();

function send(ws: WebSocket, message: ServerMessage) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(message));
  }
}

function makeRoomId(): string {
  return randomBytes(3).toString("hex").toUpperCase(); // 6 hex chars
}

function findRoomBySocket(ws: WebSocket): { roomId: string; room: Room } | null {
  for (const [roomId, room] of rooms.entries()) {
    if (room.host === ws || room.client === ws) {
      return { roomId, room };
    }
  }
  return null;
}

wss.on("connection", (ws) => {
  ws.on("message", (raw) => {
    let msg: ClientMessage;

    try {
      msg = JSON.parse(raw.toString()) as ClientMessage;
    } catch {
      send(ws, { type: "error", message: "Invalid JSON" });
      return;
    }
    console.log("message:", msg);

    if (msg.type === "create_room") {
      const roomId = makeRoomId();
      rooms.set(roomId, { host: ws });
      send(ws, { type: "room_created", roomId });
      return;
    }

    if (msg.type === "join_room") {
      const roomId = msg.roomId.trim().toUpperCase();
      const room = rooms.get(roomId);

      if (!room) {
        send(ws, { type: "error", message: "Room not found" });
        return;
      }

      if (room.client) {
        send(ws, { type: "error", message: "Room already full" });
        return;
      }

      room.client = ws;
      rooms.set(roomId, room);

      // 1. Tell the Joiner they successfully entered
      send(ws, { type: "room_joined", roomId });

      // 2. CHANGE THIS LINE: Tell the Host that a peer has connected!
      if (room.host && room.host.readyState === WebSocket.OPEN) {
        send(room.host, { type: "peer_joined", roomId } as any); 
      }

      return;
    }


    if (msg.type === "signal") {
      const roomId = msg.roomId.trim().toUpperCase();
      const room = rooms.get(roomId);

      if (!room) {
        send(ws, { type: "error", message: "Room not found" });
        return;
      }

      const target = room.host === ws ? room.client : room.host;

      if (!target || target.readyState !== WebSocket.OPEN) {
        send(ws, { type: "error", message: "Peer not connected yet" });
        return;
      }

      send(target, {
        type: "signal",
        roomId,
        signal: msg.signal,
      });

      return;
    }

    send(ws, { type: "error", message: "Unknown message type" });
  });

  ws.on("close", () => {
    console.log("close");
    const found = findRoomBySocket(ws);
    if (!found) return;

    const { roomId, room } = found;

    const other = room.host === ws ? room.client : room.host;
    if (other && other.readyState === WebSocket.OPEN) {
      send(other, { type: "error", message: "Peer disconnected" });
      other.close();
    }

    rooms.delete(roomId);
  });
});

console.log(`Signaling server running on ws://localhost:${PORT}`);