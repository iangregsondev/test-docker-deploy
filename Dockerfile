FROM golang:1.13-alpine as builder

WORKDIR /go/src/github.com/lightningnetwork/lnd

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

RUN apk add --no-cache --update alpine-sdk git make \
  && git clone -n https://github.com/lightningnetwork/lnd . \
  && git checkout tags/v0.11.0-beta.rc1 \
  && make \
  && make install tags="autopilotrpc chainrpc experimental invoicesrpc routerrpc signrpc walletrpc watchtowerrpc wtclientrpc"

# && git checkout d2186cc9da29853091175189268b073f49586cf0 \

# Start a new, final image to reduce size.
FROM alpine as final

RUN apk update && apk add \
    bash \
    git \
    vim


# Expose lnd ports (server, rpc).
EXPOSE 9735 10009

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/

RUN mkdir -p /root/.lnd/

# Import the config
#COPY ./lnd.conf /root/.lnd/lnd.conf
#COPY ./start.sh start.sh
#
#RUN ["chmod", "+x", "start.sh"]

ENTRYPOINT ["lnd"]