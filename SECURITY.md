# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| v0.4.x  | Yes       |
| v0.3.x  | Yes       |
| v0.2.x  | No        |
| v0.1.x  | No        |

## Reporting a Vulnerability

DO NOT open a public GitHub issue for security vulnerabilities.

### Responsible Disclosure Process

1. Email your findings to the repository owner via GitHub
2. Include in your report:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix if available

3. You will receive a response within 72 hours
4. We will work with you to understand and resolve the issue
5. Public disclosure after fix is released

## Security Standards

AuraCore implements the following security standards:

### Encryption
- Algorithm  : AES-256-GCM (NIST SP 800-38D)
- Key Size   : 256 bits
- IV Size    : 96 bits (randomly generated per operation)
- Auth Tag   : 128 bits

### Key Derivation
- Algorithm  : PBKDF2-HMAC-SHA512
- Iterations : 600,000 (exceeds NIST minimum)
- Salt Size  : 256 bits (randomly generated per vault)

### Memory Safety
- All sensitive buffers zeroed immediately after use
- SecureBuffer struct guarantees zeroing on destruction
- No sensitive data written to logs or temp files

### File Security
- Vault file: ~/.auracore/vault.enc (mode 600)
- Backup dir: ~/.auracore/backups/ (mode 700)
- Export dir: ~/.auracore/exports/ (mode 700)
- Config file: ~/.auracore/agent.cfg.enc (mode 600)

### Compliance
- NIST SP 800-38D (GCM mode)
- FIPS 140-3 Level 1 compatible
- OWASP Cryptographic Storage guidelines

## Known Limitations

- Mojo FFI bindings to libcrypto are stubs in current version
- Full cryptographic implementation requires libcrypto linkage
- CLI passphrase input uses standard stdin (no terminal masking yet)

## Security Hall of Fame

Responsible disclosures will be credited here.
