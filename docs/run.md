## Required tools

- [mise](https://mise.jdx.dev/installing-mise.html) for `elixir` and `erlang` versions management.

## Run project

### Direct installation on host machine

1. Mark project as trusted by `mise` so we can use its functionality, `mise trust`
2. Install required versions of `elixir` and `erlang` with `mise install`
3. Install project dependencies with `mix deps.get`
4. Start project with `iex -S mix phx.server`, web server will be listen on port `4000`, in case you want to use another
   port please define the environment variable `PHX_PORT` with the desired port.

### Docker installation

For `docker` setup we can run `mise run` and choose task `run_on_docker`, this will start app containers and monitoring
containers:

- `app` will listen on port `4000`
- `grafana` will listen on port `3000` and default user and password will be `admin`
- `prometheus` will run on port `9090`, this will be configured in grafana automatically so we won't need to enter here
  directly.

Grafana dashboards should be installed automatically, in case they aren't we can run `mise run` and choose
`install_grafana_dashboards`, after that we can see some dashboards for application.

## Openapi spec

There is an openapi spec already configured, we can go to http://localhost:4000/swaggerui to nagivate using `SwaggerUI`.
