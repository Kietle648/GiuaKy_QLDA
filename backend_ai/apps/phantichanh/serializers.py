# apps/phantichanh/serializers.py
from rest_framework import serializers

class UploadImageSerializer(serializers.Serializer):
    file = serializers.ImageField()
    mota = serializers.CharField(required=False, allow_blank=True)
