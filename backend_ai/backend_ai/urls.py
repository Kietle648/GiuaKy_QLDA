from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    
    path('admin/', admin.site.urls),

    # Các API chính
    path('api/nguoi-dung/', include('apps.nguoidung.urls')),
    path('api/phan-tich-anh/', include('apps.phantichanh.urls')),
    path('api/lich-su/', include('apps.lichsu.urls')),
]

# Chỉ thêm đường dẫn media khi ở chế độ DEBUG (dev)
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
