from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager


class NguoiDungManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Người dùng phải có email')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser phải có is_staff=True')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser phải có is_superuser=True')

        return self.create_user(email, password, **extra_fields)


class NguoiDung(AbstractUser):
    username = models.CharField(max_length=150, unique=False, null=True, blank=True)
    email = models.EmailField(unique=True)
    dia_chi = models.CharField(max_length=255, null=True, blank=True)
    so_dien_thoai = models.CharField(max_length=20, null=True, blank=True)
    ngay_tao = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    objects = NguoiDungManager()

    def __str__(self):
        return self.email
