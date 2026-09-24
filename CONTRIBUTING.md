# Contributing to AuraCore

Thank you for your interest in contributing to AuraCore.

## Code of Conduct

Be respectful, constructive, and professional in all interactions.

## How to Contribute

### Reporting Bugs
1. Check existing issues first
2. Open a new issue with:
   - AuraCore version
   - Steps to reproduce
   - Expected vs actual behavior
   - OS and architecture

### Suggesting Features
- Open an issue with label "enhancement"
- Describe the use case clearly
- Explain the security implications if relevant

### Submitting Code

1. Fork the repository
2. Create a feature branch:
   git checkout -b feat/your-feature-name

3. Follow code standards (see below)
4. Test your changes
5. Submit a pull request

## Code Standards

### Language Rules
- All source code, comments, variables: English only
- User-facing CLI output: German only
- No mixing of languages within a single file

### Mojo Style
- Use snake_case for functions and variables
- Use PascalCase for structs
- Use UPPER_CASE for aliases and constants
- Always use explicit types
- Add docstrings to every struct and function
- Use SecureBuffer for any sensitive data
- Always wipe sensitive buffers after use

### Security Rules
- Never store secrets in plain text
- Always use AES-256-GCM for encryption
- Always generate fresh IV on every encrypt
- Always validate input before processing
- Never log sensitive values

### Commit Message Format
- feat: add new feature
- fix: fix a bug
- security: security improvement
- docs: documentation update
- ci: CI/CD changes
- refactor: code restructure

## Project Structure

    auracore/
    src/
        secure_vault.mojo
        agent_core.mojo
        cli_interface.mojo
        backup_manager.mojo
        export_manager.mojo
        agent_config.mojo
    web/
        index.html
        docs.html
    .github/workflows/
        build.yml
    mojoproject.toml
    CHANGELOG.md
    CONTRIBUTING.md
    LICENSE
    SECURITY.md

## Security Contributions

Security issues must NOT be reported via public issues.
See SECURITY.md for responsible disclosure policy.
