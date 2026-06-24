FROM golang:1.20-alpine
WORKDIR /app
COPY . .
RUN go build -o discovery-service ./cmd
EXPOSE 8083
CMD ["/app/discovery-service"]
