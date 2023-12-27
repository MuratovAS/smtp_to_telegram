FROM golang:1.21-alpine AS builder

RUN apk add --no-cache git ca-certificates mailcap

WORKDIR /app

COPY go.mod .
COPY go.sum .

RUN go mod download

COPY . .

# The image should be built with
# --build-arg ST_VERSION=`git describe --tags --always`
ARG ST_VERSION
ARG GOPROXY=direct
RUN CGO_ENABLED=0 GOOS=linux go build \
        -ldflags "-s -w \
            -X main.Version=${ST_VERSION:-UNKNOWN_RELEASE}" \
        -tags urfave_cli_no_docs \
        -a -o smtptg

FROM alpine

RUN apk add --no-cache ca-certificates mailcap

COPY --from=builder /app/smtptg /smtptg

USER daemon

ENV ST_SMTP_LISTEN="0.0.0.0:2525"
EXPOSE 2525

ENTRYPOINT ["/smtptg"]
