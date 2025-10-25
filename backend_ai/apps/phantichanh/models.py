from django.db import models
from nguoidung.models import NguoiDung

class PhanTichAnh(models.Model):
    nguoi_dung = models.ForeignKey(NguoiDung, on_delete=models.CASCADE)
    ten_file = models.CharField(max_length=255)
    duong_dan = models.CharField(max_length=500)
    ket_qua = models.JSONField()
    thoi_gian = models.DateTimeField(auto_now_add=True)
