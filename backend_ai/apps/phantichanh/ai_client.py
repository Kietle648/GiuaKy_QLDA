# apps/phantichanh/ai_client.py
import requests

AI_URL = 'http://127.0.0.1:8001/analyze'

def call_ai_service(file_obj):
    files = {'file': (file_obj.name, file_obj.read(), file_obj.content_type)}
    resp = requests.post(AI_URL, files=files, timeout=60)
    resp.raise_for_status()
    return resp.json()
