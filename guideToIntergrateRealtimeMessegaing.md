Build a production-ready real-time chat system with the following requirements:

1. Real-Time Messaging
- Messages must appear instantly on the recipient’s device.
- Use WebSockets (or an equivalent persistent bidirectional connection).
- The server must push messages immediately without polling.

2. Message Flow Architecture
- When a user sends a message:
    a) Immediately emit the message to the recipient if online.
    b) Return instant delivery acknowledgment to the sender.
    c) Persist the message asynchronously in the backend.

3. Asynchronous Persistence
- Saving messages to the database must not block the user experience.
- Use a background job system or message queue (e.g., Redis queue, RabbitMQ, Kafka, or similar).
- The real-time layer should not wait for database writes.

4. Offline Handling
- If the recipient is offline:
    - Store the message in the database.
    - Deliver it when the user reconnects.
    - Maintain unread message state.

5. Scalability
- Architecture must support horizontal scaling.
- WebSocket connections should work across multiple server instances.
- Use a shared pub/sub system (e.g., Redis PubSub) to sync messages between servers.

6. Reliability
- Include message delivery status:
    - sent
    - delivered
    - read
- Ensure idempotency (no duplicate messages).
- Handle reconnection gracefully.

7. Security
- Authenticate users before establishing WebSocket connection.
- Use JWT or secure session validation.
- Only allow users to access their own conversations.

8. Clean Architecture
- Separate:
    - Real-time layer (WebSocket server)
    - Business logic layer
    - Database layer
    - Background worker/queue system

9. Provide:
- Backend implementation
- Basic frontend example
- Database schema
- Deployment guidance
- Clear explanation of how messages flow through the system



Design a WhatsApp-like event-driven chat system using:

- WebSockets for real-time communication
- Redis Pub/Sub for multi-instance synchronization
- A message queue for asynchronous persistence
- PostgreSQL (or equivalent) for storage
- Horizontal scalability in cloud deployment
- Stateless backend servers

Explain the full message lifecycle from sender → server → recipient → database.

Client → WebSocket → Server
                    ↓
               Immediately forward to recipient
                    ↓
            Push to background queue
                    ↓
               Save to database async