# AuraCore Changelog

All notable changes to this project are documented here.

## [v0.4.0] - 2026-09-23
### Added
- agent_config.mojo: Full agent configuration system
- CLI: agent-config show/set/reset/keys commands
- Support for model, temperature, top_p, threads, backend tuning
- Encrypted config persistence at ~/.auracore/agent.cfg.enc

## [v0.3.0] - 2026-09-23
### Added
- export_manager.mojo: Secure secret export and import engine
- CLI: export create/list/import/revoke commands
- Three export formats: .auraexp, .json.enc, .env.enc
- Time-limited exports with 24-hour TTL
- Export passphrase separate from master vault passphrase

## [v0.2.0] - 2026-09-22
### Added
- backup_manager.mojo: Encrypted vault backup system
- CLI: backup create/list/restore/verify/delete commands
- Automatic backup rotation (max 5 backups)
- Backup integrity verification before restore

## [v0.1.0] - 2026-09-22
### Added
- secure_vault.mojo: AES-256-GCM vault engine
- agent_core.mojo: High-performance AI agent execution loop
- cli_interface.mojo: English commands / German output CLI
- PBKDF2-HMAC-SHA512 key derivation (600,000 iterations)
- SecureBuffer: automatic memory zeroing on destruction
- TokenRingBuffer: zero-allocation FIFO for token stream
- ContextWindow: sliding window with system prompt protection
- GitHub Actions CI/CD pipeline
- Vercel landing page deployment

## Security Standards
- Encryption  : AES-256-GCM (NIST SP 800-38D)
- KDF         : PBKDF2-HMAC-SHA512
- Iterations  : 600,000
- Salt        : 256-bit random per vault
- IV          : 96-bit random per lock()
- Auth Tag    : 128-bit GCM
- Compliance  : FIPS 140-3
