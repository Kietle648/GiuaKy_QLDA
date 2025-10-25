from django.urls import path
from .views import LichSuView, XoaLichSuView

urlpatterns = [
    path('', LichSuView.as_view(), name='lich-su'),
    path('xoa/<int:history_id>/', XoaLichSuView.as_view(), name='xoa-lich-su'),
]
