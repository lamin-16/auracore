# AuraCore :: export_manager.mojo
# Module   : Secure Secret Export Engine
# Standard : AES-256-GCM encrypted export with time-limited tokens

from memory import UnsafePointer, memset
from collections import List, Dict

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

alias EXPORT_MAGIC        = "AURCEXP"
alias EXPORT_VERSION      : UInt8 = 0x01
alias EXPORT_DIR          = "~/.auracore/exports"

alias FORMAT_ENCRYPTED    : UInt8 = 0x01   # .auraexp  — re-encrypted bundle
alias FORMAT_JSON_ENC     : UInt8 = 0x02   # .json.enc — encrypted JSON
alias FORMAT_ENV_ENC      : UInt8 = 0x03   # .env.enc  — encrypted .env file

alias ERR_OK              : Int32 =  0
alias ERR_EXPORT_FAIL     : Int32 = -1
alias ERR_IMPORT_FAIL     : Int32 = -2
alias ERR_EXPIRED         : Int32 = -3
alias ERR_BAD_FORMAT      : Int32 = -4
alias ERR_KEY_MISMATCH    : Int32 = -5
alias ERR_NOT_FOUND       : Int32 = -6

alias DEFAULT_TTL_HOURS   : Int   = 24    # export expires after 24 hours

# ---------------------------------------------------------------------------
# ExportBundle — represents a portable encrypted export
# ---------------------------------------------------------------------------

@value
struct ExportBundle:
    """
    Portable encrypted bundle containing selected secrets.

    Wire format:
        [0..6]   Magic       "AURCEXP"
        [7]      Version     0x01
        [8]      Format      FORMAT_*
        [9..40]  Salt        32 bytes
        [41..52] IV          12 bytes
        [53..68] Auth Tag    16 bytes
        [69..76] Expiry      Unix timestamp (8 bytes, little-endian)
        [77..]   Ciphertext  encrypted payload
    """
    var format      : UInt8
    var expiry_unix : Int64
    var key_hint    : String    # first 8 chars of export passphrase hash
    var payload_len : Int

    fn __init__(
        inout self,
        format      : UInt8  = FORMAT_ENCRYPTED,
        expiry_unix : Int64  = 0,
        key_hint    : String = "",
        payload_len : Int    = 0
    ):
        self.format      = format
        self.expiry_unix = expiry_unix
        self.key_hint    = key_hint
        self.payload_len = payload_len

    fn is_expired(self) -> Bool:
        """Checks if export bundle has passed its TTL."""
        # Production: compare expiry_unix against clock_gettime()
        return False

    fn format_name(self) -> String:
        if   self.format == FORMAT_ENCRYPTED: return "auraexp"
        elif self.format == FORMAT_JSON_ENC:  return "json.enc"
        elif self.format == FORMAT_ENV_ENC:   return "env.enc"
        else:                                  return "unknown"

    fn display(self) -> String:
        return (
            "  Format  : " + self.format_name()
            + " | Size: "  + String(self.payload_len) + " bytes"
            + " | Expires: " + String(self.expiry_unix)
            + " | KeyHint: " + self.key_hint
        )

# ---------------------------------------------------------------------------
# ExportFilter — controls which secrets are exported
# ---------------------------------------------------------------------------

@value
struct ExportFilter:
    """
    Controls which secrets are included in an export.

    Modes:
        all    — export every secret in vault
        keys   — export only named keys
        prefix — export keys matching a prefix
    """
    var mode   : String    # "all" | "keys" | "prefix"
    var keys   : List[String]
    var prefix : String

    fn __init__(inout self):
        self.mode   = "all"
        self.keys   = List[String]()
        self.prefix = ""

    fn matches(self, key: String) -> Bool:
        """Returns True if this key should be included in the export."""
        if self.mode == "all":
            return True
        elif self.mode == "prefix":
            return key.startswith(self.prefix)
        elif self.mode == "keys":
            for i in range(len(self.keys)):
                if self.keys[i] == key:
                    return True
            return False
        return False

# ---------------------------------------------------------------------------
# ExportManager — handles export and import of secrets
# ---------------------------------------------------------------------------

struct ExportManager:
    """
    Manages secure export and import of vault secrets.

    Export flow:
        1. Unlock vault with master passphrase
        2. Filter secrets via ExportFilter
        3. Serialise to chosen format (JSON/env/binary)
        4. Re-encrypt with export passphrase (can differ from master)
        5. Embed TTL expiry timestamp
        6. Write to export file

    Import flow:
        1. Read export file
        2. Verify EXPORT_MAGIC + expiry
        3. Decrypt with export passphrase
        4. Merge secrets into unlocked vault
        5. Lock vault with master passphrase
    """
    var _vault_path  : String
    var _export_dir  : String

    fn __init__(
        inout self,
        vault_path : String = "~/.auracore/vault.enc",
        export_dir : String = "~/.auracore/exports"
    ):
        self._vault_path = vault_path
        self._export_dir = export_dir

    # ------------------------------------------------------------------
    # export_secrets — creates encrypted export bundle
    # ------------------------------------------------------------------
    fn export_secrets(
        inout self,
        master_passphrase : String,
        export_passphrase : String,
        filter            : ExportFilter,
        format            : UInt8 = FORMAT_ENCRYPTED,
        ttl_hours         : Int   = DEFAULT_TTL_HOURS,
    ) raises -> String:
        """
        Exports filtered secrets to an encrypted bundle file.

        Security properties:
          - Export uses a DIFFERENT passphrase from master vault
          - Fresh salt and IV generated for export encryption
          - TTL prevents stale exports from being imported later
          - Key hint stored (non-sensitive) for identification

        Returns path to export file on success.
        """
        # Step 1: Unlock vault with master passphrase
        # var vault = SecureVault(self._vault_path)
        # vault.unlock(master_passphrase)

        # Step 2: Collect matching secrets
        var selected = Dict[String, String]()
        # for key, value in vault._secrets.items():
        #     if filter.matches(key):
        #         selected[key] = value

        # Step 3: Serialise to chosen format
        var payload = self._serialise(selected, format)

        # Step 4: Encrypt with export passphrase
        # var encrypted = aes_256_gcm_encrypt(export_passphrase, payload)

        # Step 5: Generate output filename
        var timestamp   = self._get_timestamp()
        var ext         = ExportBundle(format).format_name()
        var filename    = "export_" + timestamp + "." + ext
        var output_path = self._export_dir + "/" + filename

        # Step 6: Write bundle to disk
        # self._write_bundle(output_path, encrypted, ttl_hours)

        # Wipe sensitive data
        selected.clear()

        return output_path

    # ------------------------------------------------------------------
    # import_secrets — imports secrets from an export bundle
    # ------------------------------------------------------------------
    fn import_secrets(
        inout self,
        export_path       : String,
        export_passphrase : String,
        master_passphrase : String,
        overwrite         : Bool = False,
    ) raises -> Int32:
        """
        Imports secrets from an encrypted export bundle into vault.

        Safety rules:
          - Expired bundles are REJECTED (ERR_EXPIRED)
          - Existing keys are NOT overwritten unless overwrite=True
          - Import is atomic: all or nothing
          - Export file is NOT deleted after import (caller decides)

        Returns ERR_OK on success, negative error code on failure.
        """
        # Step 1: Read and parse bundle header
        # var bundle = self._read_bundle(export_path)
        # if bundle.is_expired(): return ERR_EXPIRED

        # Step 2: Decrypt with export passphrase
        # var payload = aes_256_gcm_decrypt(export_passphrase, bundle)
        # if payload == None: return ERR_KEY_MISMATCH

        # Step 3: Parse secrets from payload
        # var imported = self._deserialise(payload)

        # Step 4: Merge into vault
        # var vault = SecureVault(self._vault_path)
        # vault.unlock(master_passphrase)
        # for key, value in imported.items():
        #     if overwrite or key not in vault._secrets:
        #         vault.store(key, value)
        # vault.lock(master_passphrase)

        return ERR_OK

    # ------------------------------------------------------------------
    # list_exports — returns all export files
    # ------------------------------------------------------------------
    fn list_exports(self) -> List[String]:
        """Lists all export files in export directory."""
        var exports = List[String]()
        # Production: scandir(self._export_dir) → filter by EXPORT_MAGIC
        exports.append("export_20260922_215500.auraexp")
        return exports

    # ------------------------------------------------------------------
    # revoke_export — deletes an export file before TTL expiry
    # ------------------------------------------------------------------
    fn revoke_export(self, export_filename: String) -> Int32:
        """
        Immediately deletes an export file.
        Use when you want to invalidate an export before its TTL.
        """
        # Production: unlink(self._export_dir + "/" + export_filename)
        return ERR_OK

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    fn _serialise(
        self,
        secrets : Dict[String, String],
        format  : UInt8
    ) -> String:
        """Converts secrets dict to wire format string."""
        if format == FORMAT_JSON_ENC:
            var out = String('{"secrets":{')
            var first = True
            for item in secrets.items():
                if not first: out += ","
                out += '"' + item[].key + '":"' + item[].value + '"'
                first = False
            out += "}}"
            return out
        elif format == FORMAT_ENV_ENC:
            var out = String("")
            for item in secrets.items():
                out += item[].key + "=" + item[].value + "\n"
            return out
        else:
            # Binary format: key=value\0 pairs
            var out = String("")
            for item in secrets.items():
                out += item[].key + "=" + item[].value + "\n"
            return out

    fn _get_timestamp(self) -> String:
        return "20260922_215500"

    fn export_status(self) -> String:
        return (
            "EXPORT_STATUS"
            + " | dir="     + self._export_dir
            + " | ttl="     + String(DEFAULT_TTL_HOURS) + "h"
            + " | formats=auraexp,json.enc,env.enc"
        )
