# Multi-stage build for production backend
FROM elixir:1.17-alpine AS builder

# Use Tsinghua mirror for faster package downloads (China)
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

# Install build dependencies
RUN apk add --no-cache build-base git

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build env
ENV MIX_ENV=prod

# Copy mix files and fetch deps
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy source and compile
COPY . .
RUN mix compile

# Build release
RUN mix release

# Production stage
FROM alpine:3.18

# Use Tsinghua mirror for faster package downloads (China)
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

# Install runtime dependencies
RUN apk add --no-cache openssl ncurses-libs libstdc++ libgcc

WORKDIR /app

# Copy release from builder
COPY --from=builder /app/_build/prod/rel/signin_project ./

# Create non-root user
RUN adduser -D appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 4000

CMD ["/app/bin/signin_project", "start"]
