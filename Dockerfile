FROM python:3.9.25-alpine3.22 as builder

ARG TESTARG1
ARG TESTARG2

RUN echo $TESTARG1
RUN echo $TESTARG2

# Add the community repo for access to patchelf binary package
RUN echo 'https://dl-cdn.alpinelinux.org/alpine/v3.22/community/' >> /etc/apk/repositories
RUN apk --no-cache upgrade && apk --no-cache add build-base tar musl-utils openssl-dev patchelf
# patchelf-wrapper is necessary now for cx_Freeze, but not for Curator itself.
RUN pip3 install setuptools cx_Freeze patchelf-wrapper

COPY requirements.txt .
RUN ln -s /lib/libc.musl-x86_64.so.1 ldd
RUN ln -s /lib /lib64
RUN pip3 install -r requirements.txt
COPY . .
RUN python3 setup.py build_exe
RUN cp -r /build/exe.linux-*-3.9 /build/exe

FROM alpine:3.19
RUN apk --no-cache upgrade && apk --no-cache add openssl-dev expat
COPY --from=builder /build/exe /curator/
RUN mkdir /.curator

USER nobody:nobody
ENV LD_LIBRARY_PATH /curator/lib:$LD_LIBRARY_PATH
ENTRYPOINT ["/curator/curator"]
