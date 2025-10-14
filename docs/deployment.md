# Artifacts creation

For deployment this application can use `docker`, a `Dockerfile` is already defined in the project root, all the logs
are sent to `stdout` so they can be collected by any external tool.

## Environment variables

These are the environment variables required:

- `PHX_PORT`: where the application will listen for HTTP requests
- `PHX_HOST`: domain where the application will be deployed, this should match with the actual domain so requests won't
  be rejected.
- `SECRET_KEY_BASE`: seed for signing/encrypting processes, it must be at least 64 bytes long.
