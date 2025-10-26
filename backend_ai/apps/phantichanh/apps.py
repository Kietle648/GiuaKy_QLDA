# apps/phantichanh/apps.py
from django.apps import AppConfig
from ultralytics import YOLO
import os
from django.conf import settings

class PhantichanhConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.phantichanh'  # ĐÚNG PATH

    def ready(self):
        # Chỉ load 1 lần khi app khởi động
        model_path = os.path.join(
            settings.BASE_DIR,
            'ai_data', 'notebook', 'runs', 'detect',
            'license_plate_model2', 'weights', 'best.pt'
        )

        global yolo_model  # DÙNG GLOBAL ĐỂ IMPORT Ở NƠI KHÁC
        if os.path.exists(model_path):
            try:
                yolo_model = YOLO(model_path)
                print("YOLO model loaded successfully!")
            except Exception as e:
                print(f"Lỗi load model: {e}")
                yolo_model = None
        else:
            print(f"Không tìm thấy model: {model_path}")
            yolo_model = None