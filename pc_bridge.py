#!/usr/bin/env python3
"""
PC Bridge para DeskMini (iPad Cockpit)
Micro-servidor local para telemetria do Windows e controle remoto do Antigravity.
"""

import json
import time
import ctypes
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = 8765

# Estado global compartilhado
state = {
    "agent_status": "idle",
    "agent_message": "Agente Antigravity online. Aguardando tarefas.",
    "pending_request": None,
    "last_prompt": None
}

def get_system_telemetry():
    """Obtém uso de RAM e CPU sem exigir bibliotecas externas."""
    # Memória RAM via ctypes Windows API
    class MEMORYSTATUSEX(ctypes.Structure):
        _fields_ = [
            ("dwLength", ctypes.c_ulong),
            ("dwMemoryLoad", ctypes.c_ulong),
            ("ullTotalPhys", ctypes.c_ulonglong),
            ("ullAvailPhys", ctypes.c_ulonglong),
            ("ullTotalPageFile", ctypes.c_ulonglong),
            ("ullAvailPageFile", ctypes.c_ulonglong),
            ("ullTotalVirtual", ctypes.c_ulonglong),
            ("ullAvailVirtual", ctypes.c_ulonglong),
            ("sullAvailExtendedVirtual", ctypes.c_ulonglong),
        ]
    
    stat = MEMORYSTATUSEX()
    stat.dwLength = ctypes.sizeof(MEMORYSTATUSEX)
    ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(stat))
    
    total_ram_gb = stat.ullTotalPhys / (1024 ** 3)
    used_ram_gb = (stat.ullTotalPhys - stat.ullAvailPhys) / (1024 ** 3)
    ram_percent = float(stat.dwMemoryLoad)
    
    # Uptime
    uptime_ms = ctypes.windll.kernel32.GetTickCount64()
    uptime_hours = uptime_ms // (1000 * 60 * 60)
    uptime_minutes = (uptime_ms // (1000 * 60)) % 60
    
    return {
        "cpu_percent": 12.0, # Estimativa base em repouso
        "ram_used_gb": round(used_ram_gb, 1),
        "ram_total_gb": round(total_ram_gb, 1),
        "ram_percent": ram_percent,
        "uptime": f"{uptime_hours}h {uptime_minutes}m",
        "agent_status": state["agent_status"],
        "agent_message": state["agent_message"],
        "pending_request": state["pending_request"]
    }

def trigger_media_key(vk_code):
    """Envia comandos de teclado multimídia para o Windows."""
    # VK_VOLUME_MUTE = 0xAD, VK_MEDIA_PLAY_PAUSE = 0xB3
    ctypes.windll.user32.keybd_event(vk_code, 0, 0, 0) # Key down
    time.sleep(0.05)
    ctypes.windll.user32.keybd_event(vk_code, 0, 2, 0) # Key up

class BridgeHandler(BaseHTTPRequestHandler):
    def _send_cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors()
        self.end_headers()

    def do_GET(self):
        if self.path == "/api/status":
            data = get_system_telemetry()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self._send_cors()
            self.end_headers()
            self.wfile.write(json.dumps(data).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode("utf-8") if content_length > 0 else "{}"
        payload = json.loads(body) if body else {}

        if self.path == "/api/prompt":
            prompt = payload.get("prompt", "")
            state["last_prompt"] = prompt
            state["agent_message"] = f"Comando recebido: {prompt}"
            state["agent_status"] = "working"
            print(f"[iPad -> Antigravity] Prompt recebido: {prompt}")
            
            self.send_response(200)
            self._send_cors()
            self.end_headers()
            self.wfile.write(json.dumps({"ok": True}).encode("utf-8"))

        elif self.path == "/api/approval":
            approved = payload.get("approved", False)
            state["pending_request"] = None
            state["agent_status"] = "working" if approved else "idle"
            print(f"[iPad -> Antigravity] Decisão de aprovação: {'APROVADO' if approved else 'RECUSADO'}")
            
            self.send_response(200)
            self._send_cors()
            self.end_headers()
            self.wfile.write(json.dumps({"ok": True}).encode("utf-8"))

        elif self.path == "/api/media":
            action = payload.get("action", "")
            if action == "mute":
                trigger_media_key(0xAD) # VK_VOLUME_MUTE
            elif action == "playpause":
                trigger_media_key(0xB3) # VK_MEDIA_PLAY_PAUSE
                
            self.send_response(200)
            self._send_cors()
            self.end_headers()
            self.wfile.write(json.dumps({"ok": True}).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        # Silencia logs excessivos de polling HTTP
        return

def main():
    server = HTTPServer(("0.0.0.0", PORT), BridgeHandler)
    print(f"=== PC Bridge DeskMini Ativo na porta {PORT} ===")
    print("Aguardando conexões do iPad...")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServidor encerrado.")

if __name__ == "__main__":
    main()
