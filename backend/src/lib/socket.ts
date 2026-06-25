import { Server } from 'socket.io';

let ioInstance: Server | null = null;

export function setIo(io: Server) {
  ioInstance = io;
}

export function getIo(): Server | null {
  return ioInstance;
}

export function emitRoomEvent(roomId: string, event: string, payload: unknown) {
  ioInstance?.to(`room:${roomId}`).emit(event, payload);
}
