package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin:     func(r *http.Request) bool { return true },
	ReadBufferSize:  64 * 1024,
	WriteBufferSize: 64 * 1024,
}

func main() {
	http.HandleFunc("/tcp", handleTCP)
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/", handleRoot)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🌉 TCP Bridge starting on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func handleRoot(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{
  "service": "tcp-bridge",
  "usage": "wss://HOST/tcp?host=TARGET&port=PORT",
  "example": "wss://tcp-bridge-xxx.run.app/tcp?host=kafka.example.com&port=9092",
  "status": "ready"
}`))
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("ok"))
}

func handleTCP(w http.ResponseWriter, r *http.Request) {
	host := r.URL.Query().Get("host")
	port := r.URL.Query().Get("port")

	if host == "" || port == "" {
		http.Error(w, `{"error":"missing host or port query params"}`, http.StatusBadRequest)
		return
	}

	target := fmt.Sprintf("%s:%s", host, port)
	log.Printf("→ Connection request to %s", target)

	// Connect to target TCP
	tcp, err := net.DialTimeout("tcp", target, 10*time.Second)
	if err != nil {
		log.Printf("✗ Failed to connect to %s: %v", target, err)
		http.Error(w, fmt.Sprintf(`{"error":"failed to connect to %s: %v"}`, target, err), http.StatusBadGateway)
		return
	}
	defer tcp.Close()

	// Upgrade to WebSocket
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("✗ WebSocket upgrade failed: %v", err)
		return
	}
	defer ws.Close()

	log.Printf("✓ Bridge established: client ↔ %s", target)

	var wg sync.WaitGroup
	wg.Add(2)

	// WS → TCP
	go func() {
		defer wg.Done()
		for {
			_, data, err := ws.ReadMessage()
			if err != nil {
				return
			}
			if _, err := tcp.Write(data); err != nil {
				return
			}
		}
	}()

	// TCP → WS
	go func() {
		defer wg.Done()
		buf := make([]byte, 64*1024)
		for {
			n, err := tcp.Read(buf)
			if err != nil {
				return
			}
			if err := ws.WriteMessage(websocket.BinaryMessage, buf[:n]); err != nil {
				return
			}
		}
	}()

	wg.Wait()
	log.Printf("✗ Connection closed: %s", target)
}
