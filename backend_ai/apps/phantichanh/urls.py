# apps/phantichanh/urls.py
from django.urls import path
from .views import PhanTichAnhView

urlpatterns = [
    path('phan-tich/', PhanTichAnhView.as_view(), name='phan-tich'),
]
