# Procom

Service to make multiple products comparisons.

## Assumptions

- Products should be loaded using `/api/load` endpoint
- If a product already exist for the same `SKU` it will be override
- Image management is out of scope, we assume all images URLs are public so we don't need to worry about URL signing and
  ACLs
- Auth, rate limits will be handled in another layer like a api gateway

## Run

Check [run.md](./docs/run.md) for instructions about running this project on development.

## Deployment

Check [deployment](./docs/deployment.md) for configuration details about this project deployment.
