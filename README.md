# Gemini CLI Container<!-- omit from toc -->

- [Container Architecture](#container-architecture)
  - [Structure of `Dockerfile`](#structure-of-dockerfile)
  - [Security Features](#security-features)
- [Building the Container Image](#building-the-container-image)
  - [Build Arguments](#build-arguments)
- [Authentication Setup](#authentication-setup)
  - [Initial Authentication](#initial-authentication)
  - [Authentication Persistence](#authentication-persistence)
  - [Verifying Authentication](#verifying-authentication)
  - [Authentication via GEMINI\_API\_KEY](#authentication-via-gemini_api_key)
    - [When to Use API Key Authentication](#when-to-use-api-key-authentication)
    - [Obtaining a GEMINI\_API\_KEY](#obtaining-a-gemini_api_key)
    - [Using API Key with the Container](#using-api-key-with-the-container)
- [Working with Gemini CLI from the Container](#working-with-gemini-cli-from-the-container)
  - [Basic Usage Pattern](#basic-usage-pattern)
  - [Volume Mounts Explained](#volume-mounts-explained)
  - [Working Directory Context](#working-directory-context)
- [Usage Examples](#usage-examples)
  - [Interactive Session](#interactive-session)
  - [Single Command Execution](#single-command-execution)
  - [Processing Files](#processing-files)
  - [Shell Alias for Convenience](#shell-alias-for-convenience)
- [File Permissions](#file-permissions)
  - [Option 1: Build with Custom UID](#option-1-build-with-custom-uid)
  - [Option 2: Fix Permissions After Creation](#option-2-fix-permissions-after-creation)
- [Troubleshooting](#troubleshooting)
  - [Authentication Issues](#authentication-issues)
  - [File Access Issues](#file-access-issues)
  - [Container Issues](#container-issues)

A containerized version of Google's Gemini CLI tool, built with security and
portability in mind. This container provides a rootless, distroless environment
for running Gemini CLI commands while maintaining persistent authentication and
seamless file access.

## Container Architecture

### Structure of `Dockerfile`

This container uses a multi-stage build process for optimal security and size:

- **Stage 1 (Builder)**: Uses `node:20-slim` to install the `@google/gemini-cli` package
- **Stage 2 (OS Prep)**: Uses `debian:stable-slim` to prepare user configuration files
- **Final Stage**: Uses `gcr.io/distroless/nodejs20-debian12:nonroot` for a minimal, secure runtime

### Security Features

- **Rootless execution**: Runs as user `gemini` (UID 1000) instead of root
- **Distroless base**: Minimal attack surface with no shell or package managers
- **Non-privileged user**: Enhanced security through principle of least privilege

## Building the Container Image

To build the container image from the provided Dockerfile:

```bash
docker build -t gemini-cli:dev .
```

### Build Arguments

The Dockerfile supports customization through build arguments:

```bash
docker build \
  --build-arg GEMINI_CLI_VERSION=0.1.17 \
  --build-arg USERNAME=gemini \
  --build-arg UID=1000 \
  --build-arg GID=1000 \
  -t gemini-cli:dev .
```

## Authentication Setup

The Gemini CLI requires authentication with Google's services. Authentication data is stored locally in your HOME directory for persistence across container runs.

### Initial Authentication

1. **Run the container with HOME directory mapping**:

   ```bash
   docker run -it -v $HOME:/home/gemini --rm gemini-cli:dev
   ```

1. **Follow the authentication prompts** that appear when the container starts. The CLI will guide you through the OAuth flow.

1. **Authentication storage**: Your credentials will be stored in `$HOME/.config/gemini-cli/` on your host system, which is mapped to `/home/gemini/.config/gemini-cli/` inside the container.

### Authentication Persistence

The authentication setup persists because:

- The container maps your host `$HOME` to `/home/gemini` inside the container
- Gemini CLI stores credentials in the user's home directory
- Subsequent container runs will reuse the existing authentication

### Verifying Authentication

To verify your authentication is working:

```bash
docker run -it -v $HOME:/home/gemini --rm gemini-cli:dev --help
```
If authentication is successful, you should see the Gemini CLI help without authentication prompts.

### Authentication via GEMINI_API_KEY

As an alternative to the OAuth flow described above, you can authenticate using a GEMINI_API_KEY environment variable. This method is particularly useful for automation, CI/CD pipelines, and scripting scenarios where interactive authentication is not feasible.

#### When to Use API Key Authentication

- **Automation and scripting**: When running Gemini CLI in automated environments
- **CI/CD pipelines**: For continuous integration and deployment workflows
- **Non-interactive environments**: Where OAuth browser flow is not available
- **Simplified setup**: When you prefer a single environment variable over persistent credential storage

#### Obtaining a GEMINI_API_KEY

1. **Google AI Studio** (Recommended):
   - Visit [Google AI Studio](https://aistudio.google.com/)
   - Navigate to the API keys section
   - Create a new API key for your project

2. **Google Cloud Console**:
   - Access the Google Cloud Console
   - Enable the Gemini API for your project
   - Create credentials and generate an API key

#### Using API Key with the Container

When using API key authentication, you don't need to map your HOME directory for credential persistence. Simply pass the API key as an environment variable:

**Basic usage with API key**:

```bash
docker run -it -v ${PWD}:/work -e GEMINI_API_KEY=your_actual_api_key --rm gemini-cli:dev
```

**Using environment file for API key**:

```bash
# Create a .env file with your API key
echo "GEMINI_API_KEY=your_actual_api_key" > .env

# Use the environment file with Docker
docker run -it -v ${PWD}:/work --env-file .env --rm gemini-cli:dev
```

Note that with API key authentication, the simplified volume mounting only requires `-v ${PWD}:/work` for file access, making the container commands shorter and more suitable for automation.

## Working with Gemini CLI from the Container

For practical usage, you'll want to access files from your current working directory. Use both volume mounts for full functionality:

### Basic Usage Pattern

```bash
docker run -it -v $HOME:/home/gemini -v ${PWD}:/work --rm gemini-cli:dev [GEMINI_CLI_ARGS]
```

### Volume Mounts Explained

- **`-v $HOME:/home/gemini`**: Maps your home directory for authentication persistence
- **`-v ${PWD}:/work`**: Maps your current working directory to the container's working directory
- **`--rm`**: Automatically removes the container after execution
- **`-it`**: Provides interactive terminal access

### Working Directory Context

The container sets `/work` as the working directory, which corresponds to your current directory (`${PWD}`) on the host system. This means:

- Files in your current directory are accessible within the container
- Output files created by Gemini CLI will appear in your current directory
- Relative paths work as expected

## Usage Examples

### Interactive Session

Start an interactive session to run multiple commands:

```bash
docker run -it -v $HOME:/home/gemini -v ${PWD}:/work --rm gemini-cli:dev
```

### Single Command Execution

Run a single Gemini CLI command:

```bash
docker run -it -v $HOME:/home/gemini -v ${PWD}:/work --rm gemini-cli:dev generate "Explain this code" --file ./script.py
```

### Processing Files

Work with files in your current directory:

```bash
# Analyze a document
docker run -it -v $HOME:/home/gemini -v ${PWD}:/work --rm gemini-cli:dev analyze --file ./document.txt

# Generate content and save to file
docker run -it -v $HOME:/home/gemini -v ${PWD}:/work --rm gemini-cli:dev generate "Create a summary" --output ./summary.txt
```

### Shell Alias for Convenience

Create a shell alias for easier usage:

```bash
# Add to your ~/.bashrc or ~/.zshrc
alias gemini='docker run -it -v $HOME:/home/gemini -v ${PWD}:/work --rm gemini-cli:dev'

# Then use simply:
gemini --help
gemini generate "Hello, world!"
```

## File Permissions

The container runs as user `gemini` with UID 1000. If your host user has a different UID, you may encounter permission issues. To resolve this:

### Option 1: Build with Custom UID

```bash
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t gemini-cli:dev .
```

### Option 2: Fix Permissions After Creation

```bash
# If files are created with wrong permissions
sudo chown -R $(id -u):$(id -g) ./output-files
```

## Troubleshooting

### Authentication Issues

**Problem**: Authentication prompts appear on every run
**Solution**: Ensure `$HOME` is properly mapped and authentication completed successfully

**Problem**: Permission denied accessing config files
**Solution**: Check that `$HOME/.config` is writable by your user

### File Access Issues

**Problem**: Cannot access files in current directory
**Solution**: Ensure you're using `-v ${PWD}:/work` volume mount

**Problem**: Created files have wrong ownership
**Solution**: Rebuild container with your UID/GID or fix permissions afterward

### Container Issues

**Problem**: Container fails to start
**Solution**: Verify Docker is running and image was built successfully

**Problem**: Command not found errors
**Solution**: Ensure you're passing arguments after the image name
