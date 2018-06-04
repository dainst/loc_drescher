FROM elixir:alpine

COPY . /loc_drescher

WORKDIR /loc_drescher

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix compile