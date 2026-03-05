FROM python:3.12-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates build-essential && rm -rf /var/lib/apt/lists/*
# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && mv /root/.local/bin/uv /root/.local/bin/uvx /usr/local/bin/

WORKDIR /app
COPY . .
ENV PYTHONUNBUFFERED=1
# Install deps only (uv); then project as editable with no-build-isolation (avoids slow isolated build)
RUN uv sync --no-dev --no-install-project -v
RUN uv pip install setuptools wheel
RUN uv pip install -e . --no-build-isolation --no-deps -v
RUN uv pip install cx_Freeze patchelf-wrapper pip
RUN uv run python3 setup.py build_exe
# Normalize path so final stage works on both amd64 and arm64 (exe.linux-x86_64-3.12 or exe.linux-aarch64-3.12)
RUN cp -a build/exe.linux-*-3.12 build/exe

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends libssl3 libexpat1 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/build/exe /curator/
RUN mkdir /.curator

USER nobody:nogroup
ENV LD_LIBRARY_PATH=/curator/lib
ENTRYPOINT ["/curator/curator"]
