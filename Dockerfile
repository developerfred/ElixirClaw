FROM elixir:1.19-alpine AS builder

WORKDIR /app

RUN apk add --no-cache nodejs npm

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix local.rebar --force && \
    mix local.hex --force && \
    mix deps.get --only prod

COPY . .
RUN mix escript.build

FROM alpine:3.19

WORKDIR /app

RUN apk add --no-cache \
    bash \
    ffmpeg \
    libv4l-utils \
    curl \
    scrot \
    imagemagick \
    notify-send

COPY --from=builder /app/elixir_claw .

RUN chmod +x elixir_claw

ENV MIX_ENV=prod
ENV ELIXIR_CLAW_HOST=127.0.0.1
ENV ELIXIR_CLAW_PORT=18789

ENTRYPOINT ["./elixir_claw"]
CMD ["--help"]
