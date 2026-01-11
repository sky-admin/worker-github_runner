# Repository Guidelines

## Project Structure & Module Organization
- `src/handler.py` holds the RunPod serverless handler that provisions runners, scrubs runtime variables, and shuts the runner down.
- `builder/requirements.txt` pins Python dependencies (`runpod`, `requests`) for both the worker and the CI job; install only from here.
- `.github/workflows/` contains deployment and CI templates such as `TEMPLATE-run_worker_tests.yml` and `CD-docker_*.yml` that orchestrate RunPod jobs and Docker pushes.
- `Dockerfile`, `action.yml`, and `docs/usage.md` explain how the container is assembled and how the worker integrates with CI/CD; keep any new instructions inside `docs/`.

## Build, Test, and Development Commands
- Install tooling once per shell:  
  ```powershell
  python -m pip install --upgrade pip
  pip install -r builder/requirements.txt
  ```
- Build the runnable image with `docker build -t runpod/worker-github_runner .`; pass `--build-arg` when experimenting with alternative bases.
- Dry-run the handler without deploying by replaying an event payload:  
  ```powershell
  python src/handler.py --test_input='{"input":"healthcheck"}'
  ```
- Treat `.github/workflows/TEMPLATE-run_worker_tests.yml` as the source of truth for verification and keep docs in sync when commands change.

## Coding Style & Naming Conventions
- Python code targets 3.11 with PEP 8 conventions: 4-space indentation, lowercase_with_underscores for functions, UPPER_SNAKE_CASE for constants and environment variables.
- Keep network calls wrapped with helpers (`get_token`, `run_command`) and raise actionable errors.
- GitHub workflow names follow the `CI | ...` / `CD | ...` pattern; step IDs should stay unique and descriptive (`run_tests`, `extract_id`).

## Testing Guidelines
- The test workflow boots a scoped RunPod job via `initialize_runner`, executes `python src/handler.py --test_input='{"input":"test"}'`, and always runs `terminate_runner`; match that lifecycle in new workflows.
- For local validation, export `GITHUB_PAT`, `GITHUB_ORG`, and `RUNPOD_ENDPOINT` before running the handler, and capture logs to confirm subprocess output.
- When adding automated tests, place them under `tests/`, name files `test_<feature>.py`, and run them with `pytest` after installing from `builder/requirements.txt`.

## Commit & Pull Request Guidelines
- Follow the current history by writing short, imperative commits (`Update package version`, `Fix runner token lookup`) and reference an issue/PR number when applicable (`123-runner-cleanup` branch naming is encouraged).
- Each PR should describe the change, outline validation (commands run, workflow links, logs), and call out any secrets or infrastructure changes; add screenshots only when a UI view clarifies the result.

## Security & Configuration Tips
- Never commit secrets; load `GITHUB_PAT`, `GITHUB_ORG`, `RUNPOD_API_KEY`, and `RUNPOD_ENDPOINT` through repository secrets or ignored `.env` files.
- After modifying Docker or workflow files, double-check requested permissions plus HTTP headers/timeouts before shipping.
