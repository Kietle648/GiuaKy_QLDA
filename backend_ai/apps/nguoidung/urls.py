# apps/nguoidung/urls.py
from django.urls import path
from .views import DangKyView, XacThucOtpView, DoiMatKhauView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('dang-ky/', DangKyView.as_view(), name='dang-ky'),
    path('xac-thuc-otp/', XacThucOtpView.as_view(), name='xac-thuc-otp'),
    path('doi-mat-khau/', DoiMatKhauView.as_view(), name='doi-mat-khau'),
    path('dang-nhap/', TokenObtainPairView.as_view(), name='token_obtain_pair'),  # returns access & refresh
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
