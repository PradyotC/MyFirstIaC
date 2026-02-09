// backend/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"path/filepath"
)

func main() {
	// 1. Configuration
	ollamaURL := "http://localhost:11434" // Default Ollama port
	port := ":8080"

	// Relative path to the frontend/dist folder we created earlier
	// Ensure you run this go program from the 'backend' folder
	staticDir := "../frontend/dist"

	// 2. Setup Reverse Proxy for /api/
	target, err := url.Parse(ollamaURL)
	if err != nil {
		log.Fatal("Error parsing Ollama URL:", err)
	}
	proxy := httputil.NewSingleHostReverseProxy(target)

	// Custom Director to ensure the Host header is set correctly for the target
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)
		req.Host = target.Host
		// Keep the path exactly as is (e.g. /api/chat -> /api/chat)
		// If you wanted to strip /api you would do it here, but Ollama expects /api
	}

	// 3. Define Handlers

	// Handler for API requests (proxies to Ollama)
	http.HandleFunc("/api/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf("Proxying request: %s %s\n", r.Method, r.URL.Path)

		// CORS resolution is implicit here because we are on the same origin.
		// But if you ever needed to force headers, you could do it here:
		// w.Header().Set("Access-Control-Allow-Origin", "*")

		proxy.ServeHTTP(w, r)
	})

	// Handler for Static Files (React App)
	fs := http.FileServer(http.Dir(staticDir))

	// We use a custom handler for static files to support React Router (SPA)
	// If a file isn't found (like /dashboard), serve index.html
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Check if file exists in static dir
		path := filepath.Join(staticDir, r.URL.Path)
		_, err := os.Stat(path)

		// If the path asks for /api but didn't match the specific handler above,
		// or if it's a real file, serve it.
		// Otherwise serve index.html for SPA routing.
		if os.IsNotExist(err) && r.URL.Path != "/" {
			// If it's an API call that failed, don't serve HTML
			if len(r.URL.Path) >= 4 && r.URL.Path[0:5] == "/api/" {
				http.Error(w, "API Endpoint not found", http.StatusNotFound)
				return
			}
			// SPA Catch-all: serve index.html
			http.ServeFile(w, r, filepath.Join(staticDir, "index.html"))
			return
		}

		fs.ServeHTTP(w, r)
	})

	// 4. Start Server
	fmt.Printf("Server starting on http://localhost%s\n", port)
	fmt.Printf("Serving static files from: %s\n", staticDir)
	fmt.Printf("Proxying /api/ to: %s\n", ollamaURL)

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal(err)
	}
}
