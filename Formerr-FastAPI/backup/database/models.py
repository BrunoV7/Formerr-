from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey, JSON, Float
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from datetime import datetime
import uuid
from app.database.connection import Base
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey, JSON, Enum as SQLEnum
from app.auth.models import UserRole


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    github_id = Column(Integer, unique=True, index=True, nullable=False)
    username = Column(String(255), unique=True, index=True, nullable=False)
    name = Column(String(255))
    email = Column(String(255))
    avatar_url = Column(Text)
    github_url = Column(Text)

    # 🔥 BEAST MODE: Advanced Auth
    role = Column(SQLEnum(UserRole), default=UserRole.FREE, nullable=False)
    subscription_expires = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True)

    # Usage tracking
    monthly_submissions_used = Column(Integer, default=0)
    monthly_reset_date = Column(DateTime, default=datetime.utcnow)

    # Team features (Enterprise)
    team_id = Column(String(255), nullable=True)
    invited_by = Column(Integer, ForeignKey("users.id"), nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login = Column(DateTime, default=datetime.utcnow)

    # Relationships
    forms = relationship("Form", back_populates="owner", cascade="all, delete-orphan")


class Team(Base):
    __tablename__ = "teams"

    id = Column(String(255), primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)

    # Owner
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    # Settings
    settings = Column(JSONB, default=dict)

    # Limits
    max_members = Column(Integer, default=10)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    owner = relationship("User")


class Webhook(Base):
    __tablename__ = "webhooks"

    id = Column(String(255), primary_key=True, index=True)
    form_id = Column(String(255), ForeignKey("forms.id", ondelete="CASCADE"))

    # Webhook config
    url = Column(Text, nullable=False)
    events = Column(JSONB, default=list)  # ['submission.created', 'form.updated']
    secret = Column(String(255), nullable=True)

    # Status
    active = Column(Boolean, default=True)
    last_triggered = Column(DateTime, nullable=True)
    failure_count = Column(Integer, default=0)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    form = relationship("Form", back_populates="webhooks")

class Form(Base):
    __tablename__ = "forms"
    
    # Identificação
    id = Column(String, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # 🔧 CONFIGURAÇÕES INICIAIS (/forms/new)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    max_responses = Column(Integer, nullable=True)  # null = ilimitado
    icon = Column(String(10), nullable=True)  # emoji
    banner_image_url = Column(String(500), nullable=True)  # Pexels image
    
    # 🔒 PRIVACIDADE E ACESSO
    is_private = Column(Boolean, default=False)
    authorized_emails = Column(JSON, nullable=True)  # lista de emails autorizados
    expires_at = Column(DateTime, nullable=True)  # data de expiração
    
    # 📝 ESTRUTURA DO FORMULÁRIO
    sections = Column(JSON, nullable=True)  # seções com perguntas
    """
    Estrutura sections:
    [
        {
            "id": "section_1",
            "title": "Dados Pessoais",
            "description": "Informações básicas",
            "order": 1,
            "questions": [
                {
                    "id": "q_1",
                    "type": "short-text",
                    "title": "Nome completo",
                    "description": "Digite seu nome",
                    "required": true,
                    "options": null,
                    "order": 1
                }
            ]
        }
    ]
    """
    
    # 🎨 CUSTOMIZAÇÃO VISUAL
    folder_color = Column(String(20), nullable=True)
    folder_color_dark = Column(String(20), nullable=True)
    
    # 📊 ESTADOS E CONFIGURAÇÕES
    status = Column(String(20), default="draft")  # draft, open, paused, archived, closed, completed, waiting
    is_published = Column(Boolean, default=False)
    allow_multiple_submissions = Column(Boolean, default=True)
    
    # 📈 ANALYTICS E METADADOS
    view_count = Column(Integer, default=0)
    response_count = Column(Integer, default=0)
    completion_rate = Column(Float, default=0.0)
    avg_completion_time = Column(Integer, default=0)  # segundos
    
    # 🕐 TIMESTAMPS
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    published_at = Column(DateTime, nullable=True)
    last_response_at = Column(DateTime, nullable=True)
    
    # Relationships
    owner = relationship("User", back_populates="forms")
    responses = relationship("FormResponse", back_populates="form", cascade="all, delete-orphan")
    webhooks = relationship("Webhook", back_populates="form", cascade="all, delete-orphan")
    analytics = relationship("FormAnalytics", back_populates="form", cascade="all, delete-orphan")


class FormResponse(Base):
    __tablename__ = "form_responses"
    
    id = Column(String, primary_key=True)
    form_id = Column(String, ForeignKey("forms.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # 🔐 IDENTIFICAÇÃO DO RESPONDENTE
    respondent_email = Column(String(255), nullable=True)  # null se anônimo
    respondent_id = Column(String(50), nullable=True)  # ID aleatório para privados
    
    # 📝 DADOS DA RESPOSTA
    responses = Column(JSON, nullable=False)  # respostas por pergunta
    """
    Estrutura responses:
    {
        "q_1": "João Silva",
        "q_2": ["opcao_1", "opcao_3"],
        "q_3": 8
    }
    """
    
    # 📊 METADADOS
    completion_time = Column(Integer, nullable=True)  # segundos para completar
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    
    # 🕐 TIMESTAMPS
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    form = relationship("Form", back_populates="responses")


# Analytics table para métricas
class FormAnalytics(Base):
    __tablename__ = "form_analytics"

    id = Column(Integer, primary_key=True, index=True)
    form_id = Column(String(255), ForeignKey("forms.id", ondelete="CASCADE"))
    event_type = Column(String(50))  # view, start, submit, abandon
    timestamp = Column(DateTime, default=datetime.utcnow)
    user_agent = Column(Text, nullable=True)
    referrer = Column(Text, nullable=True)
    ip_hash = Column(String(64), nullable=True)

    # Relationships
    form = relationship("Form", back_populates="analytics")