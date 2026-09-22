# AuraCore - Local AI Agent Framework in Mojo

Ultra-fast | Local | AES-256-GCM | Zero-Dependency

## Usage

    auracore init
    auracore start
    auracore encrypt-status
    auracore status
    auracore help

## Security

Encryption     : AES-256-GCM
Key Derivation : PBKDF2-HMAC-SHA512 / 600k iterations
Salt           : 256-bit random
IV/Nonce       : 96-bit random per lock
Auth Tag       : 128-bit GCM

## Project Structure

    auracore/
    src/
        secure_vault.mojo
        agent_core.mojo
        cli_interface.mojo
    mojoproject.toml
    README.md
