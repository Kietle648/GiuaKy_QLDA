from django.db import models
from nguoidung.models import NguoiDung

class LichSu(models.Model):
    nguoi_dung = models.ForeignKey(NguoiDung, on_delete=models.CASCADE)
    hanh_dong = models.CharField(max_length=255)
    thoi_gian = models.DateTimeField(auto_now_add=True)
    ghi_chu = models.TextField(null=True, blank=True)
