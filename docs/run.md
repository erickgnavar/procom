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

TBD
