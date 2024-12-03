"""
URL configuration for users application.
"""

from django.urls import path
from .views import UserViewSet

urlpatterns = [
    path("register/", UserViewSet.as_view({"post": "register"}), name="register-user"),
    path("", UserViewSet.as_view({"get": "list"}), name="user-list"),
    path("profile/", UserViewSet.as_view({"get": "profile"}), name="user-profile"),
    path("<int:pk>/", UserViewSet.as_view({"get": "retrieve", "put": "update", "delete": "destroy"}), name="user-detail"),
    path("<int:pk>/deactivate/", UserViewSet.as_view({"post": "deactivate"}), name="user-deactivate"),
]
