FROM python:3.12-alpine3.19 AS builder

# Add the community repo for patchelf
RUN echo 'https://dl-cdn.alpinelinux.org/alpine/v3.19/community/' >> /etc/apk/repositories
RUN apk --no-cache upgrade && apk --no-cache add build-base tar musl-utils openssl-dev patchelf curl
# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && mv /root/.local/bin/uv /root/.local/bin/uvx /usr/local/bin/
# patchelf-wrapper is necessary for cx_Freeze
RUN uv pip install setuptools cx_Freeze patchelf-wrapper

RUN ln -s /lib/libc.musl-x86_64.so.1 ldd || true
RUN ln -s /lib /lib64 || true
COPY . .
RUN uv sync --no-dev
RUN python3 setup.py build_exe

FROM alpine:3.19
RUN apk --no-cache upgrade && apk --no-cache add openssl-dev expat
COPY --from=builder build/exe.linux-x86_64-3.12 /curator/
RUN mkdir /.curator

USER nobody:nobody
ENV LD_LIBRARY_PATH /curator/lib:$LD_LIBRARY_PATH
ENTRYPOINT ["/curator/curator"]
