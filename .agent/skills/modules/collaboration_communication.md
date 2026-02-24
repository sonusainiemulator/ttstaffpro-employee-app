# Collaboration & Communication Module Skill

This skill covers Tasks, Notice Board, and Chat functionality.

## 📝 Task Management
- **States**: Start, Hold, Resume, Complete.
- **Service**: Updated via specialized endpoints like `taskStatusUpdate`.
- **Files**: Some task status updates require an image/file proof (`taskStatusUpdateFile`).

## 📢 Notice Board
- **Logic**: Simple read-only fetch of announcements.
- **Persistence**: Notices are saved to `noticeBoardBox` so they are accessible even when the server is unreachable.

## 💬 Chat & Calls
- **Real-time**: Leverages `socket_io_client` for live messaging.
- **Calls**: Uses **Agora SDK** (controlled by `isAgoraCallModuleEnabled`). 
- **Workflow**: 
  1. Initiate call via `initiateCall` endpoint to get a token.
  2. Join Agora channel with the token.
  3. Listen for incoming socket events to show the "Incoming Call" overlay.

## 🚀 Pro-Tip: "Socket Lifecycle"
Ensure the socket connection is established in `main.dart` or a global `ChatStore` and properly disconnected on app termination to prevent battery drain.
