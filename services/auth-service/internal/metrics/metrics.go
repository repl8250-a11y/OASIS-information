package metrics

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	RequestsTotal = prometheus.NewCounterVec(prometheus.CounterOpts{
		Name: "oasis_auth_requests_total",
		Help: "Total number of HTTP requests handled by auth-service",
	}, []string{"method", "path", "status"})

	RequestDuration = prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "oasis_auth_request_duration_seconds",
		Help:    "Request duration in seconds",
		Buckets: prometheus.DefBuckets,
	}, []string{"method", "path"})
)

func Register() {
	prometheus.MustRegister(RequestsTotal, RequestDuration)
}

func Handler() http.Handler {
	return promhttp.Handler()
}
