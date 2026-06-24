package main

import (
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("DISCOVERY_PORT")
	if port == "" {
		port = "8083"
	}
	
	http.HandleFunc("/api/v1/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
		w.Write([]byte(`{"status":"ok"}`))
	})
	log.Printf("discovery-service listening on %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
