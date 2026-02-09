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
	ollamaURL := os.Getenv("OLLAMA_HOST")
	if ollamaURL == "" {
		ollamaURL = "http://localhost:11434" // Fallback if env var is missing
	}
    
    // CHANGE: Listen on port 80 instead of 8080
	port := ":80" 

	// Relative path to the frontend/dist folder
	staticDir := "../frontend/dist"

	// 2. Setup Reverse Proxy for /api/
	target, err := url.Parse(ollamaURL)
	if err != nil {
		log.Fatal("Error parsing Ollama URL:", err)
	}
	proxy := httputil.NewSingleHostReverseProxy(target)

	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)
		req.Host = target.Host
	}

	// 3. Define Handlers
	http.HandleFunc("/api/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf("Proxying request: %s %s\n", r.Method, r.URL.Path)
		proxy.ServeHTTP(w, r)
	})

	fs := http.FileServer(http.Dir(staticDir))

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		path := filepath.Join(staticDir, r.URL.Path)
		_, err := os.Stat(path)

		if os.IsNotExist(err) && r.URL.Path != "/" {
			if len(r.URL.Path) >= 4 && r.URL.Path[0:5] == "/api/" {
				http.Error(w, "API Endpoint not found", http.StatusNotFound)
				return
			}
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