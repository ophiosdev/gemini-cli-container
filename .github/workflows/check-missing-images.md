# Workflow Documentation: Check Missing Container Images

## Overview

The **Check Missing Container Images** workflow automates the process of verifying that all tagged versions of the repository have corresponding container images available in the GitHub Container Registry (GHCR). If any version tags are missing container images, it can optionally trigger a build and deployment workflow for those missing versions.

### Workflow Triggers

This workflow runs on:

- **Manual trigger** via [`workflow_dispatch`](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_dispatch)
- **Scheduled trigger** via cron job daily at `06:00 UTC`

### Main Job: `check-missing-images`

Runs on `ubuntu-latest`.

#### Steps Breakdown

##### 1. **Checkout repository**

- Uses [`actions/checkout@v5`](https://github.com/actions/checkout)
- Fetches full history and tags.

##### 2. **List version tags**

- Retrieves all tags starting with `v`.
- Sorts them in reverse order.
- Publishes them as `tags` output for downstream steps.

##### 3. **Check GHCR for existing images**

- **Environment Variables:**
  - `TOKEN`: Auth token for GHCR (prefers `GHCR_READ_TOKEN`, falls back to `GITHUB_TOKEN`).
  - `SKIP_TAGS`: Optional regex patterns (from repository variables) to skip certain tags.
  - `GHCR_ORG`: Target GHCR organization (default: repository owner).
  - `GHCR_CONTAINER`: Container name in GHCR.
- Uses GitHub API to list available image tags in GHCR.
- Compares GHCR tags to repository tags.
- Reports missing images and skips those matching `SKIP_TAGS`.
- Outputs newline-separated list of missing tags as `missing_tags` for downstream consumption.

##### 4. **Generate GitHub App token**

- Uses [`actions/create-github-app-token@v2`](https://github.com/actions/create-github-app-token) to authenticate for triggering another workflow.

##### 5. **Trigger build-and-deploy for missing tags**

- If `missing_tags` output is not empty:
  - Uses `gh` CLI to trigger the build workflow (configurable via `BUILD_WORKFLOW` repo variable, default: `build-and-deploy.yml`).
  - Runs for each missing tag.

### Key Variables & Secrets

| Name                       | Type     | Purpose                                             | Default                | Required                        |
| -------------------------- | -------- | --------------------------------------------------- | ---------------------- | ------------------------------- |
| `GHCR_READ_TOKEN`          | Secret   | Auth token for reading GHCR images.                 | —                      | No (defaults to `GITHUB_TOKEN`) |
| `GITHUB_TOKEN`             | Secret   | Default GH Actions token, fallback for GHCR access. | (auto-generated)       | Yes, provided by GitHub         |
| `SKIP_TAGS`                | Variable | Regex patterns to skip specific tags.               | (none)                 | No                              |
| `GHCR_ORG`                 | Variable | GHCR organization.                                  | repository owner       | No                              |
| `GHCR_CONTAINER`           | Variable | GHCR container name.                                | —                      | Yes                             |
| `VERSION_PREFIX`           | Variable | Tag prefix filter. Empty string matches all tags.   | `v`                    | No                              |
| `BUILD_WORKFLOW`           | Variable | Workflow file to trigger for builds.                | `build-and-deploy.yml` | No                              |
| `WORKFLOW_APP_ID`          | Secret   | GitHub App ID for auth.                             | —                      | Yes                             |
| `WORKFLOW_APP_PRIVATE_KEY` | Secret   | GitHub App private key for auth.                    | —                      | Yes                             |

### API Endpoints Used

- **List container versions:**

  ```bash
  GET https://api.github.com/orgs/${GHCR_ORG}/packages/container/${GHCR_CONTAINER}/versions
  ```

### Usage Notes

- Ensure `GHCR_CONTAINER` is set in repository variables.
- Use `SKIP_TAGS` to ignore pre-releases or experimental versions.
- Requires `gh` CLI installed in the runner (pre-installed on `ubuntu-latest`).
