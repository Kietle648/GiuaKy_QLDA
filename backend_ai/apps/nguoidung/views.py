from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.utils import timezone
from django.conf import settings
from django.core.mail import send_mail
from django.db import connection
from .serializers import DangKySerializer, XacThucOtpSerializer
from django.contrib.auth import get_user_model
import random
from datetime import timedelta
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import DangNhapSerializer, DoiMatKhauSerializer

User = get_user_model()
OTP_EXP_MINUTES = 10

class DangKyView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = DangKySerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data['email']
        if User.objects.filter(email=email).exists():
            return Response({"detail": "Email đã được đăng ký"}, status=status.HTTP_400_BAD_REQUEST)

        otp = str(random.randint(100000, 999999))
        expires_at = timezone.now() + timedelta(minutes=OTP_EXP_MINUTES)

        with connection.cursor() as cursor:
            cursor.execute("CALL sp_create_otp(%s, %s, %s, %s);", [email, otp, 'dangky', expires_at])

        send_mail(
            subject='Mã OTP đăng ký',
            message=f'Mã OTP của bạn là: {otp}. Hết hạn sau {OTP_EXP_MINUTES} phút.',
            from_email=settings.EMAIL_HOST_USER,
            recipient_list=[email],
        )

        # Loại bỏ confirm_password trước khi lưu vào session
        validated_data = serializer.validated_data.copy()
        validated_data.pop('confirm_new_password', None)  # Không cần vì không có confirm_new_password ở đây
        validated_data.pop('confirm_password')
        # Tạm thời lưu lại thông tin đăng ký trong session (hoặc Redis)
        request.session[email] = validated_data

        return Response({"detail": "Đã gửi mã OTP. Vui lòng kiểm tra email."}, status=status.HTTP_201_CREATED)

class XacThucOtpView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = XacThucOtpSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data['email']
        otp = serializer.validated_data['otp']

        with connection.cursor() as cursor:
            cursor.execute("SELECT sp_verify_otp(%s, %s, %s);", [email, otp, 'dangky'])
            result = cursor.fetchone()

        if not result or not result[0]:
            return Response({"detail": "Mã OTP không hợp lệ hoặc đã hết hạn"}, status=status.HTTP_400_BAD_REQUEST)

        # ✅ Lấy lại thông tin từ session và tạo user
        user_data = request.session.get(email)
        if not user_data:
            return Response({"detail": "Không tìm thấy thông tin đăng ký"}, status=status.HTTP_400_BAD_REQUEST)

        # Tách password ra khỏi user_data
        password = user_data.pop('password')
        user = User.objects.create_user(**user_data, password=password, is_active=True)

        # Đánh dấu OTP đã dùng
        with connection.cursor() as cursor:
            cursor.execute("CALL sp_mark_otp_used(%s, %s, %s);", [email, otp, 'dangky'])

        # Xóa session sau khi xác thực
        del request.session[email]

        return Response({"detail": "Đăng ký và xác thực thành công"}, status=status.HTTP_201_CREATED)

class DangNhapView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = DangNhapSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {"detail": "Email hoặc mật khẩu không đúng"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        if not user.check_password(password):
            return Response(
                {"detail": "Email hoặc mật khẩu không đúng"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        if not user.is_active:
            return Response(
                {"detail": "Tài khoản chưa được kích hoạt"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Tạo JWT Token
        refresh = RefreshToken.for_user(user)
        return Response({
            "refresh": str(refresh),
            "access": str(refresh.access_token),
            "user": {
                "id": user.id,
                "email": user.email,
                "username": user.username,
            }
        }, status=status.HTTP_200_OK)

class DoiMatKhauView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = DoiMatKhauSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        user = request.user
        old_password = serializer.validated_data['old_password']
        new_password = serializer.validated_data['new_password']

        if not user.check_password(old_password):
            return Response({"detail": "Mật khẩu cũ không đúng"}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save()

        return Response({"detail": "Đổi mật khẩu thành công"}, status=status.HTTP_200_OK)