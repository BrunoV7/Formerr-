#!/usr/bin/env python3
"""
Script para gerar token JWT de teste
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.auth.service import create_jwt_token, create_user_payload
from app.auth.models import UserRole

# Dados de usuário fictício para teste
github_user_mock = {
    "id": 12345,
    "login": "test_user",
    "name": "Test User",
    "email": "test@example.com",
    "avatar_url": "https://github.com/test_user.png",
    "html_url": "https://github.com/test_user"
}

# Criar payload do usuário
user_payload = create_user_payload(
    github_user=github_user_mock,
    primary_email="test@example.com",
    user_role=UserRole.FREE
)

# Gerar token JWT
token = create_jwt_token(user_payload)

print("🔑 Token JWT gerado:")
print(token)
print()
print("📝 Para testar endpoints, use:")
print(f'curl -X GET "http://localhost:8000/auth/me" -H "Authorization: Bearer {token}"')
