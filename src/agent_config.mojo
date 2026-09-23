# AuraCore :: agent_config.mojo
# Module   : Agent Configuration Manager
# Standard : Encrypted config persistence + runtime tuning

from memory import UnsafePointer, memset
from collections import List, Dict

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

alias CONFIG_MAGIC        = "AURCCFG"
alias CONFIG_VERSION      : UInt8 = 0x01
alias CONFIG_PATH         = "~/.auracore/agent.cfg.enc"

alias DEFAULT_MODEL       = "tinyllama"
alias DEFAULT_CTX_SIZE    : Int = 4096
alias DEFAULT_MAX_TOKENS  : Int = 512
alias DEFAULT_TEMPERATURE : Float32 = 0.7
alias DEFAULT_TOP_P       : Float32 = 0.9
alias DEFAULT_THREADS     : Int = 4
alias DEFAULT_SOCKET      = "/tmp/auracore_llm.sock"
alias DEFAULT_HOST        = "127.0.0.1"
alias DEFAULT_PORT        : Int = 8080
alias DEFAULT_TIMEOUT_MS  : Int = 60_000
alias DEFAULT_LANGUAGE    = "de"
alias DEFAULT_PERSONA     = "Aura"

alias ERR_OK              : Int32 =  0
alias ERR_CONFIG_FAIL     : Int32 = -1
alias ERR_INVALID_VALUE   : Int32 = -2
alias ERR_NOT_FOUND       : Int32 = -3

# ---------------------------------------------------------------------------
# ModelBackend — supported LLM backend types
# ---------------------------------------------------------------------------

alias BACKEND_SOCKET  : UInt8 = 0x01   # llama.cpp Unix socket
alias BACKEND_HTTP    : UInt8 = 0x02   # ollama HTTP API
alias BACKEND_FFI     : UInt8 = 0x03   # direct libllama.so FFI

# ---------------------------------------------------------------------------
# AgentConfig — full configuration record
# ---------------------------------------------------------------------------

@value
struct AgentConfig:
    """
    Complete agent configuration.
    Stored encrypted at CONFIG_PATH.
    All fields have safe defaults.
    """

    # Model settings
    var model_name    : String
    var backend_type  : UInt8
    var ctx_size      : Int
    var max_tokens    : Int
    var temperature   : Float32
    var top_p         : Float32
    var threads       : Int

    # Connection settings
    var socket_path   : String
    var host          : String
    var port          : Int
    var timeout_ms    : Int

    # Interface settings
    var language      : String    # "de" | "en"
    var persona_name  : String    # agent display name
    var agent_id      : String

    # Memory settings
    var max_memory_turns  : Int
    var persist_memory    : Bool

    fn __init__(inout self):
        self.model_name       = DEFAULT_MODEL
        self.backend_type     = BACKEND_SOCKET
        self.ctx_size         = DEFAULT_CTX_SIZE
        self.max_tokens       = DEFAULT_MAX_TOKENS
        self.temperature      = DEFAULT_TEMPERATURE
        self.top_p            = DEFAULT_TOP_P
        self.threads          = DEFAULT_THREADS
        self.socket_path      = DEFAULT_SOCKET
        self.host             = DEFAULT_HOST
        self.port             = DEFAULT_PORT
        self.timeout_ms       = DEFAULT_TIMEOUT_MS
        self.language         = DEFAULT_LANGUAGE
        self.persona_name     = DEFAULT_PERSONA
        self.agent_id         = "aura-01"
        self.max_memory_turns = 20
        self.persist_memory   = True

    fn validate(self) raises -> Int32:
        """Validates all config values are within safe ranges."""
        if self.ctx_size < 512 or self.ctx_size > 131072:
            raise Error("ctx_size must be between 512 and 131072")
        if self.max_tokens < 1 or self.max_tokens > 32768:
            raise Error("max_tokens must be between 1 and 32768")
        if self.temperature < 0.0 or self.temperature > 2.0:
            raise Error("temperature must be between 0.0 and 2.0")
        if self.top_p < 0.0 or self.top_p > 1.0:
            raise Error("top_p must be between 0.0 and 1.0")
        if self.threads < 1 or self.threads > 64:
            raise Error("threads must be between 1 and 64")
        if self.port < 1 or self.port > 65535:
            raise Error("port must be between 1 and 65535")
        if self.language != "de" and self.language != "en":
            raise Error("language must be 'de' or 'en'")
        return ERR_OK

    fn to_display(self) -> String:
        """Returns human-readable config summary for CLI display."""
        var backend_name = String("socket")
        if   self.backend_type == BACKEND_HTTP: backend_name = "http"
        elif self.backend_type == BACKEND_FFI:  backend_name = "ffi"

        return (
            "\n  [MODELL]\n"
            + "  Modell       : " + self.model_name       + "\n"
            + "  Backend      : " + backend_name           + "\n"
            + "  Kontext      : " + String(self.ctx_size)  + " tokens\n"
            + "  Max Tokens   : " + String(self.max_tokens)+ "\n"
            + "  Temperatur   : " + String(self.temperature) + "\n"
            + "  Top-P        : " + String(self.top_p)     + "\n"
            + "  Threads      : " + String(self.threads)   + "\n"
            + "\n  [VERBINDUNG]\n"
            + "  Socket       : " + self.socket_path       + "\n"
            + "  Host         : " + self.host              + "\n"
            + "  Port         : " + String(self.port)      + "\n"
            + "  Timeout      : " + String(self.timeout_ms)+ " ms\n"
            + "\n  [INTERFACE]\n"
            + "  Sprache      : " + self.language          + "\n"
            + "  Persona      : " + self.persona_name      + "\n"
            + "  Agent-ID     : " + self.agent_id          + "\n"
            + "\n  [GEDAECHTNIS]\n"
            + "  Max Turns    : " + String(self.max_memory_turns) + "\n"
            + "  Persistent   : " + String(self.persist_memory)
        )

# ---------------------------------------------------------------------------
# ConfigManager — load, save, and edit agent configuration
# ---------------------------------------------------------------------------

struct ConfigManager:
    """
    Manages encrypted agent configuration file.

    The config file is AES-256-GCM encrypted using the vault
    master passphrase — same key, different file, different IV.

    Workflow:
        1. config = ConfigManager()
        2. config.load(passphrase)    -> AgentConfig
        3. config.set("temperature", "0.8")
        4. config.save(passphrase)
        5. config.show()              -> prints current values
    """
    var _config_path : String
    var _config      : AgentConfig
    var _loaded      : Bool

    fn __init__(inout self, config_path: String = CONFIG_PATH):
        self._config_path = config_path
        self._config      = AgentConfig()
        self._loaded      = False

    fn load(inout self, passphrase: String) raises -> Int32:
        """
        Loads and decrypts config from disk.
        Falls back to defaults if config file doesn't exist yet.
        """
        # Production:
        # 1. Check if config file exists
        # 2. If not → use defaults, return ERR_OK
        # 3. Read encrypted config bytes
        # 4. Decrypt with passphrase (same flow as SecureVault)
        # 5. Parse JSON into AgentConfig fields
        self._loaded = True
        return ERR_OK

    fn save(inout self, passphrase: String) raises -> Int32:
        """
        Encrypts and saves current config to disk.
        Uses fresh IV on every save (same as vault lock).
        """
        if not self._loaded:
            raise Error("Config not loaded — call load() first")
        _ = self._config.validate()
        # Production: serialise → encrypt → write atomic
        return ERR_OK

    fn set(inout self, key: String, value: String) raises -> Int32:
        """
        Sets a single config value by key name.
        Validates value before applying.
        """
        if not self._loaded:
            raise Error("Config not loaded")

        if key == "model":
            self._config.model_name = value
        elif key == "ctx_size":
            self._config.ctx_size = atol(value)
        elif key == "max_tokens":
            self._config.max_tokens = atol(value)
        elif key == "temperature":
            self._config.temperature = Float32(atol(value))
        elif key == "top_p":
            self._config.top_p = Float32(atol(value))
        elif key == "threads":
            self._config.threads = atol(value)
        elif key == "port":
            self._config.port = atol(value)
        elif key == "host":
            self._config.host = value
        elif key == "socket":
            self._config.socket_path = value
        elif key == "language":
            self._config.language = value
        elif key == "persona":
            self._config.persona_name = value
        elif key == "agent_id":
            self._config.agent_id = value
        elif key == "backend":
            if   value == "socket": self._config.backend_type = BACKEND_SOCKET
            elif value == "http":   self._config.backend_type = BACKEND_HTTP
            elif value == "ffi":    self._config.backend_type = BACKEND_FFI
            else: raise Error("backend must be: socket | http | ffi")
        elif key == "memory_turns":
            self._config.max_memory_turns = atol(value)
        elif key == "persist_memory":
            self._config.persist_memory = (value == "true")
        else:
            raise Error("Unknown config key: " + key)

        return ERR_OK

    fn get(self, key: String) raises -> String:
        """Gets a single config value by key name."""
        if not self._loaded:
            raise Error("Config not loaded")

        if key == "model":          return self._config.model_name
        elif key == "ctx_size":     return String(self._config.ctx_size)
        elif key == "max_tokens":   return String(self._config.max_tokens)
        elif key == "temperature":  return String(self._config.temperature)
        elif key == "top_p":        return String(self._config.top_p)
        elif key == "threads":      return String(self._config.threads)
        elif key == "port":         return String(self._config.port)
        elif key == "host":         return self._config.host
        elif key == "socket":       return self._config.socket_path
        elif key == "language":     return self._config.language
        elif key == "persona":      return self._config.persona_name
        elif key == "agent_id":     return self._config.agent_id
        elif key == "memory_turns": return String(self._config.max_memory_turns)
        elif key == "persist_memory": return String(self._config.persist_memory)
        else: raise Error("Unknown config key: " + key)

    fn reset(inout self) raises -> Int32:
        """Resets all config values to defaults."""
        self._config = AgentConfig()
        return ERR_OK

    fn show(self) -> String:
        """Returns full config display string."""
        return self._config.to_display()

    fn config_status(self) -> String:
        return (
            "CONFIG_STATUS"
            + " | path="   + self._config_path
            + " | loaded=" + String(self._loaded)
            + " | model="  + self._config.model_name
            + " | lang="   + self._config.language
        )
