# apps/phantichanh/views.py
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.conf import settings
from django.utils import timezone
from django.db import connection
from rest_framework.parsers import MultiPartParser, FormParser
from pathlib import Path
import os
import json
import uuid
import cv2
import shutil
from .serializers import UploadImageSerializer
from .apps import yolo_model  # ✅ import model đã load sẵn

class PhanTichAnhView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = UploadImageSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        file = serializer.validated_data["file"]

        # ===== 1. Lưu ảnh gốc =====
        user_folder = os.path.join("uploads", str(request.user.id))
        save_dir = os.path.join(settings.MEDIA_ROOT, user_folder)
        os.makedirs(save_dir, exist_ok=True)

        timestamp = int(timezone.now().timestamp())
        filename = f"{timestamp}_{file.name}"
        filepath = os.path.join(save_dir, filename)
        relative_path = os.path.join(user_folder, filename)

        with open(filepath, "wb") as f:
            for chunk in file.chunks():
                f.write(chunk)

        # ===== 2. Chạy YOLO =====
        if yolo_model is None:
            return Response({"detail": "YOLO model chưa được load"}, status=500)

        try:
            results = yolo_model.predict(source=filepath, conf=0.4, save=False)
        except Exception as e:
            return Response({"detail": f"Lỗi YOLO: {str(e)}"}, status=500)

        # ===== 3. Xử lý kết quả =====
        objects = []
        img = cv2.imread(filepath)

        if img is None:
            return Response({"detail": "Không đọc được ảnh gốc"}, status=500)

        for result in results:
            boxes = result.boxes.xyxy.cpu().numpy()
            confs = result.boxes.conf.cpu().numpy()
            classes = result.boxes.cls.cpu().numpy()

            for box, conf, cls in zip(boxes, confs, classes):
                x1, y1, x2, y2 = map(int, box)
                label = f"{yolo_model.names[int(cls)]} {conf:.2f}"
                objects.append({
                    "label": yolo_model.names[int(cls)],
                    "confidence": float(conf),
                    "bbox": [x1, y1, x2, y2]
                })

                # ✅ Vẽ khung lên ảnh
                cv2.rectangle(img, (x1, y1), (x2, y2), (0, 0, 255), 2)
                cv2.putText(img, label, (x1, y1 - 10),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)

        # ===== 4. Lưu ảnh annotate =====
        annotated_folder = os.path.join(settings.MEDIA_ROOT, "uploads", str(request.user.id), "annotated")
        os.makedirs(annotated_folder, exist_ok=True)

        ext = Path(file.name).suffix or ".jpg"
        annotated_filename = f"annotated_{uuid.uuid4().hex}{ext}"
        annotated_path = os.path.join(annotated_folder, annotated_filename)
        cv2.imwrite(annotated_path, img)
        relative_annotated_path = os.path.join("uploads", str(request.user.id), "annotated", annotated_filename)

        # ===== 5. Tạo JSON kết quả =====
        ai_result = {
            "objects": objects,
            "summary": f"Phát hiện {len(objects)} đối tượng",
            "annotated_image": relative_annotated_path
        }

        # ===== 6. Lưu DB =====
        analysis_time = timezone.now()
        try:
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT save_analysis_result(%s, %s, %s, %s::jsonb, %s)",
                    [request.user.id, file.name, relative_path, json.dumps(ai_result, ensure_ascii=False), analysis_time]
                )
                new_id = cursor.fetchone()[0]
        except Exception as e:
            return Response({"detail": f"Lỗi lưu DB: {str(e)}"}, status=500)

        # ===== 7. Trả về kết quả =====
        response = Response({
            "detail": "Phân tích thành công",
            "id": new_id,
            "ten_file": file.name,
            "duong_dan": relative_path,
            "duong_dan_anh_danh_dau": relative_annotated_path,
            "ket_qua": ai_result,
            "thoi_gian": analysis_time.isoformat()
        }, status=200)

        # No-cache headers
        response['Cache-Control'] = 'no-cache, no-store, must-revalidate, max-age=0'
        response['Pragma'] = 'no-cache'
        response['Expires'] = '0'
        return response
