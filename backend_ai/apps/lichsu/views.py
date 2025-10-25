# apps/lichsu/views.py
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db import connection
from rest_framework import status

class LichSuView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user_id = request.user.id
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM get_user_history(%s)", [user_id])
            columns = [col[0] for col in cursor.description]
            results = [dict(zip(columns, row)) for row in cursor.fetchall()]
        return Response(results, status=status.HTTP_200_OK)


class XoaLichSuView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, history_id):
        user_id = request.user.id
        try:
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT delete_image_history(%s, %s)",
                    [history_id, user_id]
                )
            return Response({"detail": "Đã xóa lịch sử thành công"}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {"detail": str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )