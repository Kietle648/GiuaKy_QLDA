# apps/phantichanh/views.py
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.conf import settings
from django.utils import timezone
import os
import json
from .serializers import UploadImageSerializer
from .ai_client import call_ai_service
from django.db import connection

class PhanTichAnhView(APIView):
    permission_classes = [IsAuthenticated]

    def postave_annotated_image(ai_result, user_id, original_filename):
        """Lưu ảnh đã đánh dấu (nếu AI trả base64 hoặc bytes)"""
        annotated_data = ai_result.get("annotated_image")  # giả sử base64
        if not annotated_data:
            return None

        import base64
        from pathlib import Path

        user_folder = os.path.join('uploads', str(user_id), 'annotated')
        save_dir = os.path.join(settings.MEDIA_ROOT, user_folder)
        os.makedirs(save_dir, exist_ok=True)

        ext = Path(original_filename).suffix or '.jpg'
        filename = f"annotated_{int(timezone.now().timestamp())}{ext}"
        filepath = os.path.join(save_dir, filename)
        relative_path = os.path.join(user_folder, filename)

        # Giải mã base64 → lưu file
        with open(filepath, 'wb') as f:
            f.write(base64.b64decode(annotated_data.split(',', 1)[1] if ',' in annotated_data else annotated_data))

        return relative_path

    def post(self, request):
        serializer = UploadImageSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        file = serializer.validated_data['file']
        mota = serializer.validated_data.get('mota', '')

        # === 1. Lưu ảnh gốc ===
        user_folder = os.path.join('uploads', str(request.user.id))
        save_dir = os.path.join(settings.MEDIA_ROOT, user_folder)
        os.makedirs(save_dir, exist_ok=True)

        timestamp = int(timezone.now().timestamp())
        filename = f"{timestamp}_{file.name}"
        filepath = os.path.join(save_dir, filename)
        relative_path = os.path.join(user_folder, filename)

        with open(filepath, 'wb') as f:
            for chunk in file.chunks():
                f.write(chunk)

        # === 2. Gọi AI ===
        with open(filepath, 'rb') as f:
            ai_result = call_ai_service(f)

        # === 3. Lưu ảnh đã đánh dấu (nếu có) ===
        annotated_path = self.save_annotated_image(ai_result, request.user.id, file.name)

        # === 4. Chuẩn bị dữ liệu DB ===
        analysis_time = timezone.now()
        result_json = json.dumps({
            "objects": ai_result.get("objects", []),
            "summary": ai_result.get("summary", ""),
            "annotated_image": annotated_path  # thêm đường dẫn ảnh đánh dấu
        }, ensure_ascii=False)

        # === 5. Gọi PostgreSQL function ===
        try:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT save_analysis_result(%s, %s, %s, %s::jsonb, %s)
                    """,
                    [
                        request.user.id,
                        file.name,           # ten_file
                        relative_path,       # duong_dan
                        result_json,         # ket_qua
                        analysis_time        # thoi_gian
                    ]
                )
                new_id = cursor.fetchone()[0]
        except Exception as e:
            return Response(
                {"detail": f"Lỗi lưu dữ liệu: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        # === 6. Trả về kết quả ===
        return Response({
            "detail": "Phân tích ảnh thành công",
            "id": new_id,
            "ten_file": file.name,
            "duong_dan": relative_path,
            "duong_dan_anh_danh_dau": annotated_path,
            "ket_qua": json.loads(result_json),
            "thoi_gian": analysis_time.isoformat()
        }, status=status.HTTP_200_OK)