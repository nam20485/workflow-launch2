# Opencode ACP Integration - Implementation Plan

## Overview

Create an ACP (Agent Client Protocol) adapter that enables Opencode.ai to work as an external agent in Zed editor and other ACP-compatible clients.

## Architecture

### High-Level Design

```
┌─────────────────┐
│   Zed Editor    │
│  (ACP Client)   │
└────────┬────────┘
         │ JSON-RPC over stdin/stdout
         │
┌────────▼────────┐
│  opencode-acp   │
│   (Adapter)     │
│                 │
│ - ACP Agent     │
│ - HTTP Client   │
│ - Event Bridge  │
└────────┬────────┘
         │ HTTP REST API + SSE
         │
┌────────▼────────┐
│ Opencode Server │
│  (localhost)    │
└─────────────────┘
```

### Component Responsibilities

1. **ACP Agent Interface**: Implements `@zed-industries/agent-client-protocol` AgentSideConnection
2. **Opencode HTTP Client**: Wrapper around opencode's REST API
3. **Session Manager**: Maps ACP session IDs to Opencode session IDs
4. **Event Handler**: Listens to opencode SSE events and converts to ACP notifications
5. **CLI Entry Point**: Handles command-line arguments and stdio setup

## Protocol Mapping

### ACP → Opencode API

| ACP Method | Opencode API | Notes |
|------------|--------------|-------|
| `initialize` | `GET /app` | Verify server connection |
| `authenticate` | `PUT /auth/:id` | Set provider credentials |
| `newSession` | `POST /session` | Create new session |
| `loadSession` | `GET /session/:id` | Load existing session |
| `prompt` | `POST /session/:id/message` | Send user message |
| `cancel` | `POST /session/:id/abort` | Abort running operation |
| `setSessionMode` | N/A | Mode changes (if applicable) |

### Opencode Events → ACP Notifications

| Opencode Event | ACP Notification | Mapping |
|----------------|------------------|---------|
| `message.created` | `sessionUpdate` (agent_message_chunk) | Stream message content |
| `tool.call` | `sessionUpdate` (tool_call) | Tool execution started |
| `tool.result` | `sessionUpdate` (tool_call_update) | Tool execution completed |
| `permission.required` | `requestPermission` | Ask user for approval |
| `session.complete` | Stop reason in prompt response | End of turn |

### File Operations

- Use opencode's `/find`, `/find/file`, `/find/symbol` for searches
- Use opencode's `/file?path=` for reading files
- Map to ACP's file system capabilities

## Project Structure

```
opencode-acp/
├── src/
│   ├── index.ts              # CLI entry point
│   ├── agent.ts              # ACP Agent implementation
│   ├── opencode-client.ts    # HTTP client for opencode API
│   ├── session-manager.ts    # Session mapping and state
│   ├── event-handler.ts      # SSE event → ACP notification bridge
│   ├── types.ts              # TypeScript type definitions
│   └── utils.ts              # Helper functions
├── tests/
│   ├── unit/
│   │   ├── agent.test.ts
│   │   ├── opencode-client.test.ts
│   │   └── session-manager.test.ts
│   └── integration/
│       └── e2e.test.ts
├── examples/
│   └── config.md             # Example Zed configuration
├── .github/
│   └── workflows/
│       ├── test.yml          # Run tests on PR
│       ├── build.yml         # Build and type-check
│       └── publish.yml       # Publish to npm
├── package.json
├── tsconfig.json
├── .gitignore
├── .prettierrc
├── .eslintrc.json
├── LICENSE
├── README.md
└── IMPLEMENTATION_PLAN.md
```

## Dependencies

### Production Dependencies

```json
{
  "@zed-industries/agent-client-protocol": "^0.4.5",
  "axios": "^1.7.0",
  "eventsource": "^2.0.2",
  "commander": "^12.0.0"
}
```

### Development Dependencies

```json
{
  "typescript": "^5.6.0",
  "@types/node": "^22.0.0",
  "@types/eventsource": "^1.1.15",
  "vitest": "^2.0.0",
  "@vitest/ui": "^2.0.0",
  "tsx": "^4.0.0",
  "prettier": "^3.3.0",
  "eslint": "^9.0.0"
}
```

## Implementation Phases

### Phase 1: Project Setup ✓
- [x] Initialize TypeScript project
- [x] Configure build system (tsconfig, package.json)
- [x] Setup linting and formatting
- [x] Create directory structure
- [x] Install dependencies

### Phase 2: Opencode Client Implementation
- [ ] Implement HTTP client wrapper for opencode API
  - [ ] App endpoints (`/app`, `/app/init`)
  - [ ] Config endpoints (`/config`, `/config/providers`)
  - [ ] Session endpoints (create, get, delete, message)
  - [ ] File endpoints (read, find, status)
  - [ ] Auth endpoints (`/auth/:id`)
- [ ] Implement SSE event listener (`/event`)
- [ ] Error handling and retries
- [ ] Connection management (start server if not running)
- [ ] Unit tests for client

### Phase 3: Session Management
- [ ] Create SessionManager class
  - [ ] Map ACP session IDs to Opencode session IDs
  - [ ] Track session state (active, cancelled, completed)
  - [ ] Handle concurrent sessions
  - [ ] Cleanup on session end
- [ ] Unit tests for session manager

### Phase 4: ACP Agent Core
- [ ] Implement Agent class with AgentSideConnection
  - [ ] `initialize()` - verify opencode connection
  - [ ] `authenticate()` - handle auth methods
  - [ ] `newSession()` - create opencode session
  - [ ] `loadSession()` - resume existing session
  - [ ] `setSessionMode()` - handle mode changes
  - [ ] `cancel()` - abort operations
- [ ] Handle stdin/stdout communication
- [ ] Unit tests for agent

### Phase 5: Prompt & Response Handling
- [ ] Implement `prompt()` method
  - [ ] Convert ACP prompt to opencode message format
  - [ ] Handle context (files, symbols, etc.)
  - [ ] Send to opencode API
  - [ ] Stream responses back via sessionUpdate
- [ ] Handle message parts (text, code, images)
- [ ] Handle tool calls and results
- [ ] Unit tests

### Phase 6: Event Bridge
- [ ] EventHandler class
  - [ ] Listen to opencode SSE stream
  - [ ] Parse event types
  - [ ] Convert to ACP sessionUpdate notifications
  - [ ] Handle event errors and reconnection
- [ ] Tool call mapping
  - [ ] Read operations → kind: "read"
  - [ ] Write operations → kind: "edit"
  - [ ] Shell commands → kind: "command"
- [ ] Permission request handling
- [ ] Unit tests

### Phase 7: CLI & Entry Point
- [ ] Command-line argument parsing
  - [ ] `--port` - opencode server port
  - [ ] `--host` - opencode server host
  - [ ] `--start-server` - auto-start opencode
  - [ ] `--debug` - enable debug logging
- [ ] Server lifecycle management
- [ ] Graceful shutdown handling
- [ ] Logging configuration

### Phase 8: Integration Testing
- [ ] E2E test with mock opencode server
- [ ] Test full prompt → response flow
- [ ] Test session management
- [ ] Test cancellation
- [ ] Test error scenarios
- [ ] Test with real opencode server (manual)

### Phase 9: Documentation
- [ ] README.md
  - [ ] Installation instructions
  - [ ] Usage with Zed
  - [ ] Configuration options
  - [ ] Troubleshooting
- [ ] API documentation (JSDoc)
- [ ] Example configurations
- [ ] Architecture diagram
- [ ] Contributing guide

### Phase 10: CI/CD Pipeline
- [ ] GitHub Actions workflow for tests
- [ ] Build workflow (type-check, build)
- [ ] Automated npm publishing
- [ ] Version management
- [ ] Release notes automation

### Phase 11: Testing with Zed
- [ ] Install in Zed as custom agent
- [ ] Test basic chat functionality
- [ ] Test file operations
- [ ] Test tool calls and permissions
- [ ] Test session persistence
- [ ] Performance testing

### Phase 12: Polish & Release
- [ ] Handle edge cases
- [ ] Optimize performance
- [ ] Add telemetry/analytics (optional)
- [ ] Security review
- [ ] Publish to npm
- [ ] Announce release

## Key Implementation Details

### ACP Agent Class Structure

```typescript
class OpencodeAgent implements acp.Agent {
  private connection: acp.AgentSideConnection;
  private opencodeClient: OpencodeClient;
  private sessionManager: SessionManager;
  private eventHandler: EventHandler;

  async initialize(params: acp.InitializeRequest): Promise<acp.InitializeResponse>;
  async authenticate(params: acp.AuthenticateRequest): Promise<acp.AuthenticateResponse>;
  async newSession(params: acp.NewSessionRequest): Promise<acp.NewSessionResponse>;
  async loadSession(params: acp.LoadSessionRequest): Promise<acp.LoadSessionResponse>;
  async prompt(params: acp.PromptRequest): Promise<acp.PromptResponse>;
  async cancel(params: acp.CancelNotification): Promise<void>;
  async setSessionMode(params: acp.SetSessionModeRequest): Promise<acp.SetSessionModeResponse>;
}
```

### Opencode Client Interface

```typescript
class OpencodeClient {
  constructor(baseURL: string);

  // App
  async getApp(): Promise<App>;
  async initApp(): Promise<boolean>;

  // Sessions
  async createSession(parentID?: string, title?: string): Promise<Session>;
  async getSession(id: string): Promise<Session>;
  async deleteSession(id: string): Promise<void>;
  async sendMessage(sessionId: string, input: ChatInput): Promise<Message>;
  async abortSession(sessionId: string): Promise<void>;

  // Events
  getEventStream(): EventSource;

  // Files
  async readFile(path: string): Promise<FileContent>;
  async findFiles(query: string): Promise<string[]>;
  async findText(pattern: string): Promise<SearchResult[]>;

  // Auth
  async setAuth(providerId: string, credentials: any): Promise<boolean>;
}
```

### Event Handling Flow

```typescript
eventHandler.on('message.chunk', (event) => {
  connection.sessionUpdate({
    sessionId: mapToACPSessionId(event.sessionId),
    update: {
      sessionUpdate: 'agent_message_chunk',
      content: { type: 'text', text: event.content }
    }
  });
});

eventHandler.on('tool.call', (event) => {
  connection.sessionUpdate({
    sessionId: mapToACPSessionId(event.sessionId),
    update: {
      sessionUpdate: 'tool_call',
      toolCallId: event.toolId,
      title: event.title,
      kind: mapToolKind(event.operation),
      status: 'pending',
      locations: event.files.map(f => ({ path: f })),
      rawInput: event.input
    }
  });
});
```

## Configuration

### Zed Settings

```json
{
  "agent_servers": {
    "opencode": {
      "command": "npx",
      "args": ["opencode-acp", "--port", "4096"],
      "env": {}
    }
  }
}
```

### With Custom Opencode Path

```json
{
  "agent_servers": {
    "opencode": {
      "command": "node",
      "args": ["/path/to/opencode-acp/dist/index.js", "--start-server"],
      "env": {
        "OPENCODE_PORT": "4096",
        "OPENCODE_HOST": "127.0.0.1"
      }
    }
  }
}
```

## Testing Strategy

### Unit Tests
- Test each component in isolation
- Mock dependencies
- Focus on business logic

### Integration Tests
- Test component interactions
- Mock opencode HTTP API
- Test full message flows

### E2E Tests
- Test with real opencode server
- Manual testing in Zed
- Performance and stress testing

## Success Criteria

1. ✅ Successfully connects to opencode server
2. ✅ Creates and manages sessions
3. ✅ Sends prompts and streams responses
4. ✅ Handles file operations
5. ✅ Processes tool calls with permissions
6. ✅ Gracefully handles errors and cancellation
7. ✅ Works in Zed editor with full functionality
8. ✅ Documented and published to npm
9. ✅ CI/CD pipeline operational

## Timeline Estimate

- **Phase 1**: 1 day (Setup)
- **Phase 2**: 2-3 days (Opencode client)
- **Phase 3**: 1 day (Session management)
- **Phase 4**: 2 days (ACP agent core)
- **Phase 5**: 2 days (Prompt handling)
- **Phase 6**: 2-3 days (Event bridge)
- **Phase 7**: 1 day (CLI)
- **Phase 8**: 2 days (Integration tests)
- **Phase 9**: 1-2 days (Documentation)
- **Phase 10**: 1 day (CI/CD)
- **Phase 11**: 1-2 days (Zed testing)
- **Phase 12**: 1 day (Polish)

**Total: ~15-20 days**

## Risk Mitigation

### Risk: Opencode API changes
- **Mitigation**: Version lock opencode, monitor for breaking changes, use OpenAPI spec if available

### Risk: Event streaming complexity
- **Mitigation**: Thorough testing of SSE connection, implement reconnection logic

### Risk: ACP protocol updates
- **Mitigation**: Lock ACP library version, monitor for updates, plan migration path

### Risk: Performance issues
- **Mitigation**: Profile early, optimize hot paths, consider caching

## Future Enhancements

1. **Session persistence**: Save/restore sessions across restarts
2. **Multi-model support**: Allow switching models within session
3. **Custom tools**: Register additional tools
4. **Telemetry**: Usage analytics for improvement
5. **Web UI**: Optional web interface for debugging
6. **MCP integration**: Model Context Protocol support
7. **Plugin system**: Allow extending functionality

## References

### Documentation
- [Opencode Server API](https://opencode.ai/docs/server/#apis)
- [Agent Client Protocol](https://agentclientprotocol.com)
- [Zed External Agents](https://zed.dev/docs/ai/external-agents)
- [ACP TypeScript Library](https://www.npmjs.com/package/@zed-industries/agent-client-protocol)
- [Gemini CLI Reference Implementation](https://github.com/google-gemini/gemini-cli)
