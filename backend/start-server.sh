#!/bin/bash
cd "$(dirname "$0")"
pkill -f "uvicorn main:app" 2>/dev/null
sleep 1
source .venv/bin/activate
echo "Footprint 서버 시작: http://0.0.0.0:8000"
echo "실기기용 주소: http://$(ipconfig getifaddr en0 2>/dev/null || echo '맥IP'):8000"
exec uvicorn main:app --host 0.0.0.0 --port 8000
