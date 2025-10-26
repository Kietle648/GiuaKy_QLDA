import os
from ultralytics import YOLO
from django.conf import settings

# Đường dẫn tuyệt đối đến model YOLO
MODEL_PATH = os.path.join(settings.BASE_DIR, 'ai_data', 'weights', 'best.pt')

model = YOLO(MODEL_PATH)
