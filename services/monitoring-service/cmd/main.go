package main

import (
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("MONITOR_PORT")
	if port == "" { port = "8092" }
	
	http.HandleFunc("/api/v1/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
		w.Write([]byte(`{"status":"ok"}`))
	})
	log.Printf("monitoring-service listening on %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
