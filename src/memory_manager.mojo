# AuraCore :: memory_manager.mojo
# Module   : Conversation Memory and Prompt Template Manager

from collections import List, Dict

alias MEMORY_PATH    = "~/.auracore/memory.enc"
alias TEMPLATES_PATH = "~/.auracore/templates.enc"
alias MAX_TURNS      : Int = 100
alias MAX_TMPL_LEN   : Int = 4096

@value
struct ConversationTurn:
    var role      : String
    var content   : String
    var timestamp : String
    var tokens    : Int

    fn __init__(inout self, role: String, content: String,
                timestamp: String, tokens: Int):
        self.role      = role
        self.content   = content
        self.timestamp = timestamp
        self.tokens    = tokens

    fn to_display(self) -> String:
        return "[" + self.timestamp + "] " + self.role + ": " + self.content[:80]

@value
struct PromptTemplate:
    var name        : String
    var description : String
    var template    : String
    var created_at  : String

    fn __init__(inout self, name: String, description: String,
                template: String, created_at: String):
        self.name        = name
        self.description = description
        self.template    = template
        self.created_at  = created_at

    fn to_display(self) -> String:
        return (
            "  Name: " + self.name
            + " | " + self.description
            + " | " + self.created_at
        )

struct MemoryManager:
    var _memory_path    : String
    var _templates_path : String
    var _turns          : List[ConversationTurn]
    var _templates      : Dict[String, PromptTemplate]
    var _max_turns      : Int

    fn __init__(inout self,
                memory_path    : String = MEMORY_PATH,
                templates_path : String = TEMPLATES_PATH,
                max_turns      : Int    = MAX_TURNS):
        self._memory_path    = memory_path
        self._templates_path = templates_path
        self._turns          = List[ConversationTurn]()
        self._templates      = Dict[String, PromptTemplate]()
        self._max_turns      = max_turns

    fn add_turn(inout self, role: String, content: String) -> Int:
        if len(self._turns) >= self._max_turns:
            _ = self._turns.pop(0)
        var turn = ConversationTurn(
            role, content, "2026-09-23T02:12:00Z", len(content) // 4
        )
        self._turns.append(turn)
        return len(self._turns)

    fn get_turns(self) -> List[ConversationTurn]:
        return self._turns

    fn clear_turns(inout self):
        self._turns = List[ConversationTurn]()

    fn add_template(inout self, name: String,
                    description: String, template: String) raises -> Int:
        if len(template) > MAX_TMPL_LEN:
            raise Error("Template too long")
        var tmpl = PromptTemplate(
            name, description, template, "2026-09-23T02:12:00Z"
        )
        self._templates[name] = tmpl
        return len(self._templates)

    fn get_template(self, name: String) raises -> PromptTemplate:
        if name not in self._templates:
            raise Error("Template not found: " + name)
        return self._templates[name]

    fn delete_template(inout self, name: String) -> Bool:
        if name not in self._templates:
            return False
        _ = self._templates.pop(name, PromptTemplate("","","",""))
        return True

    fn list_templates(self) -> List[String]:
        var names = List[String]()
        for item in self._templates.items():
            names.append(item[].key)
        return names

    fn total_tokens(self) -> Int:
        var total = 0
        for i in range(len(self._turns)):
            total += self._turns[i].tokens
        return total

    fn memory_status(self) -> String:
        return (
            "MEMORY_STATUS"
            + " | turns="     + String(len(self._turns))
            + " | max="       + String(self._max_turns)
            + " | tokens="    + String(self.total_tokens())
            + " | templates=" + String(len(self._templates))
        )
