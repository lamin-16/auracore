# AuraCore :: agent_core.mojo
# High-Performance Agent Execution Engine

from memory import UnsafePointer, memset
from collections import List, Dict

alias MAX_CONTEXT_TOKENS    : Int   = 4096
alias RING_BUFFER_CAPACITY  : Int   = 8192
alias LLM_SOCKET_PATH               = "/tmp/auracore_llm.sock"

alias STATE_IDLE        : UInt8 = 0x00
alias STATE_PROCESSING  : UInt8 = 0x01
alias STATE_GENERATING  : UInt8 = 0x02
alias STATE_ERROR       : UInt8 = 0xFF

alias AGENT_OK          : Int32 =  0
alias AGENT_ERR_TIMEOUT : Int32 = -1
alias AGENT_ERR_LLM     : Int32 = -2
alias AGENT_ERR_IO      : Int32 = -4

@value
struct Token:
    var id       : UInt32
    var role     : UInt8
    var reserved : UInt8

    fn __init__(inout self, id: UInt32, role: UInt8):
        self.id       = id
        self.role     = role
        self.reserved = 0

struct TokenRingBuffer:
    var _buf    : UnsafePointer[Token]
    var _head   : Int
    var _tail   : Int
    var _mask   : Int

    fn __init__(inout self, capacity: Int) raises:
        if capacity <= 0 or (capacity & (capacity - 1)) != 0:
            raise Error("TokenRingBuffer: capacity must be power of 2")
        self._buf  = UnsafePointer[Token].alloc(capacity)
        self._head = 0
        self._tail = 0
        self._mask = capacity - 1

    fn __del__(owned self):
        if self._buf:
            self._buf.free()

    @always_inline
    fn push(inout self, token: Token) -> Bool:
        var next_tail = (self._tail + 1) & self._mask
        if next_tail == self._head:
            return False
        self._buf[self._tail] = token
        self._tail = next_tail
        return True

    @always_inline
    fn pop(inout self) -> Optional[Token]:
        if self._head == self._tail:
            return None
        var token = self._buf[self._head]
        self._head = (self._head + 1) & self._mask
        return token

    @always_inline
    fn is_empty(self) -> Bool:
        return self._head == self._tail

    @always_inline
    fn size(self) -> Int:
        return (self._tail - self._head) & self._mask

struct ContextWindow:
    var _tokens      : List[Token]
    var _max_tokens  : Int
    var _system_end  : Int

    fn __init__(inout self, max_tokens: Int = MAX_CONTEXT_TOKENS):
        self._tokens     = List[Token]()
        self._max_tokens = max_tokens
        self._system_end = 0

    fn push_system(inout self, token: Token):
        self._tokens.append(token)
        self._system_end += 1

    fn push(inout self, token: Token):
        if len(self._tokens) >= self._max_tokens:
            if len(self._tokens) > self._system_end:
                _ = self._tokens.pop(self._system_end)
        self._tokens.append(token)

    fn token_count(self) -> Int:
        return len(self._tokens)

    fn clear_conversation(inout self):
        var system_tokens = List[Token]()
        for i in range(self._system_end):
            system_tokens.append(self._tokens[i])
        self._tokens = system_tokens

struct AgentMemory:
    var short_term  : Dict[String, String]
    var turn_count  : Int
    var total_tokens: Int

    fn __init__(inout self):
        self.short_term   = Dict[String, String]()
        self.turn_count   = 0
        self.total_tokens = 0

    fn record_turn(inout self, role: String, summary: String):
        var key = "turn_" + String(self.turn_count) + "_" + role
        self.short_term[key] = summary
        self.turn_count += 1

    fn stats(self) -> String:
        return (
            "turns=" + String(self.turn_count)
            + " total_tokens=" + String(self.total_tokens)
        )

struct AgentCore:
    var _state    : UInt8
    var _ctx      : ContextWindow
    var _memory   : AgentMemory
    var _ring     : TokenRingBuffer
    var _agent_id : String

    fn __init__(inout self, agent_id: String = "aura-01") raises:
        self._state    = STATE_IDLE
        self._ctx      = ContextWindow(MAX_CONTEXT_TOKENS)
        self._memory   = AgentMemory()
        self._ring     = TokenRingBuffer(RING_BUFFER_CAPACITY)
        self._agent_id = agent_id

    fn submit_input(inout self, text: String) -> Bool:
        var words = text.split(" ")
        for i in range(len(words)):
            var tok = Token(UInt32(i + 1000), 1)
            if not self._ring.push(tok):
                return False
        return True

    fn shutdown(inout self):
        self._state = STATE_IDLE
        self._ctx.clear_conversation()

    fn agent_status(self) -> String:
        var state_name = String("idle")
        if   self._state == STATE_PROCESSING:  state_name = "processing"
        elif self._state == STATE_GENERATING:  state_name = "generating"
        elif self._state == STATE_ERROR:       state_name = "error"
        return (
            "AGENT_STATUS"
            + " | id="    + self._agent_id
            + " | state=" + state_name
            + " | ctx="   + String(self._ctx.token_count())
                          + "/" + String(MAX_CONTEXT_TOKENS)
            + " | " + self._memory.stats()
        )
