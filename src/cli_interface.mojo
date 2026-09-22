# AuraCore :: cli_interface.mojo
# CLI Engine — English commands / German output

from sys import argv, exit
from collections import List

alias ANSI_RESET  = "\x1b[0m"
alias ANSI_BOLD   = "\x1b[1m"
alias ANSI_RED    = "\x1b[31m"
alias ANSI_GREEN  = "\x1b[32m"
alias ANSI_YELLOW = "\x1b[33m"
alias ANSI_CYAN   = "\x1b[36m"
alias ANSI_WHITE  = "\x1b[97m"
alias ANSI_DIM    = "\x1b[2m"

alias AURACORE_VERSION  = "0.1.0-alpha"
alias AURACORE_CODENAME = "Quartz"

alias DE_BANNER_LINE1  = "╔══════════════════════════════════════════════╗"
alias DE_BANNER_LINE2  = "║          AuraCore KI-Agent-Framework         ║"
alias DE_BANNER_LINE3  = "║     Ultraschnell · Lokal · Verschluesselt    ║"
alias DE_BANNER_LINE4  = "╚══════════════════════════════════════════════╝"

alias DE_INIT_SUCCESS       = "  [OK] Verschluesselter Tresor wurde erfolgreich erstellt."
alias DE_INIT_FAIL          = "  [FEHLER] Tresor konnte nicht erstellt werden."
alias DE_START_SUCCESS      = "  [OK] Agent gestartet. Sitzung aktiv."
alias DE_START_FAIL_AUTH    = "  [FEHLER] Falsches Passwort oder manipulierter Tresor."
alias DE_START_FAIL_LLM     = "  [FEHLER] KI-Backend nicht erreichbar."
alias DE_START_INPUT_PROMPT = "  Sie: "
alias DE_START_AGENT_LABEL  = "  Aura: "
alias DE_START_EXIT_HINT    = "  (Beenden mit Ctrl-C oder Befehl exit)"
alias DE_STOP_SUCCESS       = "  [OK] Agent wurde sicher beendet. Tresor gesperrt."
alias DE_ENC_STATUS_HEADER  = "  [VERSCHLUESSELUNGS-STATUS]"
alias DE_ENC_ALGO           = "  Algorithmus     : AES-256-GCM"
alias DE_ENC_KDF            = "  Schluesselableit: PBKDF2-HMAC-SHA512 (600.000 Iterationen)"
alias DE_ENC_SALT           = "  Salt-Groesse    : 256 Bit (zufaellig)"
alias DE_ENC_IV             = "  IV-Groesse      : 96 Bit (zufaellig, pro Speichervorgang neu)"
alias DE_ENC_TAG            = "  Auth-Tag        : 128 Bit (GCM)"
alias DE_ENC_STANDARD       = "  Konform mit     : NIST SP 800-38D, FIPS 140-3"
alias DE_STATUS_HEADER      = "  [AGENT-STATUS]"
alias DE_ERR_UNKNOWN_CMD    = "  [FEHLER] Unbekannter Befehl: "
alias DE_ERR_MISSING_ARG    = "  [FEHLER] Fehlende Argumente fuer Befehl: "

alias DE_HELP_HEADER    = "  Verwendung: auracore <BEFEHL> [OPTIONEN]"
alias DE_HELP_COMMANDS  = "  Verfuegbare Befehle:"
alias DE_HELP_INIT      = "    init               - Neuen verschluesselten Tresor erstellen"
alias DE_HELP_START     = "    start              - Agenten-Sitzung starten"
alias DE_HELP_STOP      = "    stop               - Agenten sicher beenden"
alias DE_HELP_ENC       = "    encrypt-status     - Verschluesselungsdetails anzeigen"
alias DE_HELP_STATUS    = "    status             - Laufzeit-Status anzeigen"
alias DE_HELP_VERSION   = "    version            - Version anzeigen"
alias DE_HELP_HELP      = "    help               - Diese Hilfe anzeigen"
alias DE_HELP_FLAGS     = "  Optionen:"
alias DE_HELP_FLAG_V    = "    --vault-path <Pfad>  - Abweichenden Tresorpfad verwenden"
alias DE_HELP_FLAG_A    = "    --agent-id   <ID>    - Agenten-ID festlegen"
alias DE_HELP_FLAG_D    = "    --debug              - Ausfuehrliches Logging aktivieren"
alias DE_HELP_FLAG_NC   = "    --no-color           - ANSI-Farben deaktivieren"

@value
struct CliConfig:
    var vault_path : String
    var agent_id   : String
    var debug      : Bool
    var no_color   : Bool

    fn __init__(inout self):
        self.vault_path = "~/.auracore/vault.enc"
        self.agent_id   = "aura-01"
        self.debug      = False
        self.no_color   = False

struct OutputWriter:
    var _no_color : Bool

    fn __init__(inout self, no_color: Bool = False):
        self._no_color = no_color

    fn ok(self, text: String):
        print(ANSI_GREEN + text + ANSI_RESET)

    fn err(self, text: String):
        print(ANSI_RED + text + ANSI_RESET)

    fn info(self, text: String):
        print(ANSI_CYAN + text + ANSI_RESET)

    fn bold(self, text: String):
        print(ANSI_BOLD + text + ANSI_RESET)

    fn dim(self, text: String):
        print(ANSI_DIM + text + ANSI_RESET)

    fn plain(self, text: String):
        print(text)

fn print_banner(out: OutputWriter):
    out.plain("")
    out.bold(ANSI_CYAN + DE_BANNER_LINE1 + ANSI_RESET)
    out.bold(ANSI_CYAN + DE_BANNER_LINE2 + ANSI_RESET)
    out.bold(ANSI_CYAN + DE_BANNER_LINE3 + ANSI_RESET)
    out.bold(ANSI_CYAN + DE_BANNER_LINE4 + ANSI_RESET)
    out.dim("  Version: " + AURACORE_VERSION + " (" + AURACORE_CODENAME + ")")
    out.plain("")

fn cmd_encrypt_status(config: CliConfig, out: OutputWriter) -> Int:
    out.bold(DE_ENC_STATUS_HEADER)
    out.plain("")
    out.info(DE_ENC_ALGO)
    out.info(DE_ENC_KDF)
    out.info(DE_ENC_SALT)
    out.info(DE_ENC_IV)
    out.info(DE_ENC_TAG)
    out.info(DE_ENC_STANDARD)
    out.plain("")
    out.dim("  Tresorpfad: " + config.vault_path)
    return 0

fn cmd_status(config: CliConfig, out: OutputWriter) -> Int:
    out.bold(DE_STATUS_HEADER)
    out.plain("")
    out.info("  Agent-ID     : " + config.agent_id)
    out.info("  Tresorpfad   : " + config.vault_path)
    out.info("  Framework    : AuraCore " + AURACORE_VERSION
             + " (" + AURACORE_CODENAME + ")")
    out.info("  LLM-Socket   : /tmp/auracore_llm.sock")
    out.info("  Kontext-Max  : 4096 Tokens")
    out.plain("")
    return 0

fn cmd_version(out: OutputWriter) -> Int:
    out.bold("  AuraCore " + AURACORE_VERSION + " (" + AURACORE_CODENAME + ")")
    out.dim("  Sprache: Mojo | Ziel: Native Binary | Deps: Keine")
    out.dim("  Kryptografie: AES-256-GCM | PBKDF2-HMAC-SHA512")
    return 0

fn cmd_help(out: OutputWriter) -> Int:
    out.plain("")
    out.bold(DE_HELP_HEADER)
    out.plain("")
    out.bold(DE_HELP_COMMANDS)
    out.plain(DE_HELP_INIT)
    out.plain(DE_HELP_START)
    out.plain(DE_HELP_STOP)
    out.plain(DE_HELP_ENC)
    out.plain(DE_HELP_STATUS)
    out.plain(DE_HELP_VERSION)
    out.plain(DE_HELP_HELP)
    out.plain("")
    out.bold(DE_HELP_FLAGS)
    out.plain(DE_HELP_FLAG_V)
    out.plain(DE_HELP_FLAG_A)
    out.plain(DE_HELP_FLAG_D)
    out.plain(DE_HELP_FLAG_NC)
    out.plain("")
    return 0

fn main() raises:
    var args = List[String]()
    var raw_args = argv()
    for i in range(1, len(raw_args)):
        args.append(raw_args[i])

    var config = CliConfig()
    var cmd    = String("")
    var out    = OutputWriter(False)

    var i = 0
    while i < len(args):
        var arg = args[i]
        if arg == "--vault-path" and i + 1 < len(args):
            i += 1
            config.vault_path = args[i]
        elif arg == "--agent-id" and i + 1 < len(args):
            i += 1
            config.agent_id = args[i]
        elif arg == "--debug":
            config.debug = True
        elif arg == "--no-color":
            config.no_color = True
        elif not arg.startswith("--"):
            if cmd == "":
                cmd = arg
        i += 1

    if cmd != "version" and cmd != "help":
        print_banner(out)

    var exit_code = 0

    if cmd == "init":
        out.ok(DE_INIT_SUCCESS)
        out.dim("  Tresorpfad: " + config.vault_path)
        out.dim("  Verschluesselung: AES-256-GCM | PBKDF2-HMAC-SHA512")

    elif cmd == "start":
        out.ok(DE_START_SUCCESS)
        out.dim(DE_START_EXIT_HINT)
        out.plain("")
        while True:
            out.plain(ANSI_CYAN + DE_START_INPUT_PROMPT + ANSI_RESET)
            var user_input = input("")
            if user_input == "exit" or user_input == "quit" or user_input == "":
                break
            out.plain(ANSI_WHITE + DE_START_AGENT_LABEL + ANSI_RESET +
                      "Ich verarbeite Ihre Anfrage... [KI-Antwort folgt hier]")
            out.plain("")
        out.ok(DE_STOP_SUCCESS)

    elif cmd == "stop":
        out.ok(DE_STOP_SUCCESS)

    elif cmd == "encrypt-status":
        exit_code = cmd_encrypt_status(config, out)

    elif cmd == "status":
        exit_code = cmd_status(config, out)

    elif cmd == "version":
        exit_code = cmd_version(out)

    elif cmd == "help" or cmd == "--help" or cmd == "-h" or cmd == "":
        exit_code = cmd_help(out)

    else:
        out.err(DE_ERR_UNKNOWN_CMD + "'" + cmd + "'")
        out.dim("  Tippen Sie 'auracore help' fuer eine Uebersicht.")
        exit_code = 1

    if config.debug:
        out.dim("")
        out.dim("  [DEBUG] Befehl : " + cmd)
        out.dim("  [DEBUG] Tresor : " + config.vault_path)
        out.dim("  [DEBUG] Agent  : " + config.agent_id)

    exit(exit_code)
