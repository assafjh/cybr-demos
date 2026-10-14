FROM golang:1.24-alpine AS build
WORKDIR /src
COPY go.mod ./
COPY *.go ./
RUN go test ./... && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /conjur-injector .

FROM gcr.io/distroless/static:nonroot
COPY --from=build /conjur-injector /conjur-injector
USER 65532:65532
EXPOSE 8443
ENTRYPOINT ["/conjur-injector"]
