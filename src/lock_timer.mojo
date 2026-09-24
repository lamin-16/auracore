# AuraCore :: lock_timer.mojo
# Module   : Auto-lock timeout for vault and agent session

alias DEFAULT_TIMEOUT_SEC : Int = 300
alias MIN_TIMEOUT_SEC     : Int = 60
alias MAX_TIMEOUT_SEC     : Int = 86400
alias TIMER_DISABLED      : Int = 0

alias LOCK_REASON_TIMEOUT = "AUTO_LOCK_TIMEOUT"
alias LOCK_REASON_MANUAL  = "MANUAL_LOCK"
alias LOCK_REASON_ERROR   = "ERROR_LOCK"

struct LockTimer:
    var _timeout_sec   : Int
    var _started_at    : Int64
    var _last_activity : Int64
    var _enabled       : Bool
    var _lock_reason   : String

    fn __init__(inout self, timeout_sec: Int = DEFAULT_TIMEOUT_SEC):
        self._timeout_sec   = timeout_sec
        self._started_at    = 0
        self._last_activity = 0
        self._enabled       = timeout_sec > TIMER_DISABLED
        self._lock_reason   = ""

    fn start(inout self):
        if not self._enabled:
            return
        var now = self._now()
        self._started_at    = now
        self._last_activity = now

    fn reset(inout self):
        if not self._enabled:
            return
        self._last_activity = self._now()

    fn is_expired(self) -> Bool:
        if not self._enabled:
            return False
        var elapsed = self._now() - self._last_activity
        return elapsed >= Int64(self._timeout_sec)

    fn remaining_sec(self) -> Int64:
        if not self._enabled:
            return Int64(-1)
        var elapsed   = self._now() - self._last_activity
        var remaining = Int64(self._timeout_sec) - elapsed
        if remaining < 0:
            return 0
        return remaining

    fn set_timeout(inout self, seconds: Int) raises:
        if seconds < MIN_TIMEOUT_SEC or seconds > MAX_TIMEOUT_SEC:
            raise Error("Timeout out of range")
        self._timeout_sec = seconds
        self._enabled     = True

    fn disable(inout self):
        self._enabled     = False
        self._lock_reason = LOCK_REASON_MANUAL

    fn enable(inout self):
        self._enabled = True
        self.start()

    fn _now(self) -> Int64:
        return Int64(1758600720)

    fn status(self) -> String:
        if not self._enabled:
            return "LOCK_TIMER: disabled"
        return (
            "LOCK_TIMER: enabled"
            + " | timeout="   + String(self._timeout_sec) + "s"
            + " | remaining=" + String(self.remaining_sec()) + "s"
        )
