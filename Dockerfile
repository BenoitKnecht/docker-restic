FROM golang:1.12 as build

ENV GO111MODULE=on

RUN CGO_ENABLED=0 go get github.com/restic/restic/cmd/restic@v0.9.5
RUN strip /go/bin/restic


FROM bitnami/postgresql:11.5.0-debian-9-r34

USER root
RUN install_packages jq
USER 1001

COPY --from=build /go/bin/restic /usr/local/bin/
COPY run.sh /usr/local/bin/

ENTRYPOINT ["run.sh"]
