package middleware

import (
	"log/slog"
	"net/http"
	"runtime/debug"
)

// RecoveryMiddleware recovers from panics in HTTP handlers.
// It logs the panic with a full stack trace and returns a 500 Internal Server Error.
// This prevents handler panics from crashing the entire server.
func RecoveryMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				// Get request ID from context for correlation
				reqID := GetRequestID(r.Context())

				// Log panic with full stack trace
				slog.Error("panic_recovered",
					"request_id", reqID,
					"method", r.Method,
					"path", r.URL.Path,
					"panic", err,
					"stack", string(debug.Stack()),
				)

				// Return user-friendly error (don't expose panic details)
				http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}
