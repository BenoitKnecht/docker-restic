FROM golang:1.12 as build

ENV GO111MODULE=on

RUN CGO_ENABLED=0 go get github.com/restic/restic/cmd/restic@v0.9.5


FROM gcr.io/distroless/static

COPY --from=build /go/bin/restic /bin/

ENTRYPOINT ["restic"]
