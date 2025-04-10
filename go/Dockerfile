ARG T

#
# Build: 1st stage
#
FROM golang:1.24-alpine as builder
ARG TARCH
WORKDIR /app
COPY go.mod .
COPY hello.go .
RUN GOARCH=${TARCH} go build -o /hello && \
    apk add --update --no-cache file && \
    file /hello

#
# Release: 2nd stage
#
FROM ${T}alpine
WORKDIR /
COPY --from=builder /hello /hello
RUN apk add --update --no-cache file
CMD [ "/hello" ]