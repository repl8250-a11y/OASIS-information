FROM golang:1.20-alpine
WORKDIR /app
COPY . .
RUN go build -o monitoring-service ./cmd
EXPOSE 8092
CMD ["/app/monitoring-service"]
