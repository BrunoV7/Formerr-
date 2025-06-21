"""
Database Models - Formerr
========================

Modelos de dados para o sistema de formulários seguindo estrutura normalizada:
- User: Usuários autenticados via GitHub
- Form: Formulários principais (draft, public, closed, archived, private)
- Section: Seções dentro de formulários
- Question: Perguntas dentro de seções
- ResponseSession: Sessões de resposta (uma submissão completa)
- Response: Respostas individuais por pergunta

Estrutura normalizada para facilitar analytics e performance.
"""

from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey, JSON, Float, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from datetime import datetime
import uuid
from app.database.connection import Base
from app.auth.models import UserRole
import enum


class FormStatus(enum.Enum):
    DRAFT = "draft"
    PUBLIC = "public"
    CLOSED = "closed"
    ARCHIVED = "archived"
    PRIVATE = "private"


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


class Form(Base):
    __tablename__ = "forms"
    
    # Identificação
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # 🔧 CONFIGURAÇÕES INICIAIS (/forms/new)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    icon = Column(String(10), nullable=True)  # emoji
    folder_color = Column(String(20), nullable=True)  # cor da pasta/folder
    
    # 📊 CONFIGURAÇÕES
    status = Column(SQLEnum(FormStatus), default=FormStatus.DRAFT)
    max_responses = Column(Integer, nullable=True)  # null = ilimitado
    
    # 📝 URLs E COMPARTILHAMENTO
    preview_url = Column(String(500), nullable=True)  # URL para visualização/resposta
    
    # 📈 ESTATÍSTICAS (calculadas)
    total_responses = Column(Integer, default=0)
    
    # 🕐 TIMESTAMPS
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    owner = relationship("User", back_populates="forms")
    sections = relationship("Section", back_populates="form", cascade="all, delete-orphan", order_by="Section.order")
    response_sessions = relationship("ResponseSession", back_populates="form", cascade="all, delete-orphan")


class Section(Base):
    __tablename__ = "sections"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    form_id = Column(String, ForeignKey("forms.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Conteúdo da seção
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    
    # Ordem das seções (para drag & drop)
    order = Column(Integer, nullable=False, default=1)
    
    # 🕐 TIMESTAMPS
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    form = relationship("Form", back_populates="sections")
    questions = relationship("Question", back_populates="section", cascade="all, delete-orphan", order_by="Question.order")


class Question(Base):
    __tablename__ = "questions"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    section_id = Column(String, ForeignKey("sections.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Tipo e conteúdo da pergunta
    type = Column(String(50), nullable=False)  # short-text, paragraph, multiple-choice, etc.
    title = Column(String(500), nullable=False)
    description = Column(Text, nullable=True)
    required = Column(Boolean, default=False)
    
    # Configurações específicas da pergunta (opções para multiple choice, validações, etc.)
    options = Column(JSON, nullable=True)
    validation = Column(JSON, nullable=True)
    
    # Ordem das perguntas (para drag & drop)
    order = Column(Integer, nullable=False, default=1)
    
    # 🕐 TIMESTAMPS
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    section = relationship("Section", back_populates="questions")
    responses = relationship("Response", back_populates="question", cascade="all, delete-orphan")


class ResponseSession(Base):
    """Uma sessão de respostas = uma submissão completa do formulário"""
    __tablename__ = "response_sessions"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    form_id = Column(String, ForeignKey("forms.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Informações do respondente (opcional)
    respondent_email = Column(String(255), nullable=True)
    respondent_ip = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    
    # 🕐 TIMESTAMPS
    submitted_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    form = relationship("Form", back_populates="response_sessions")
    responses = relationship("Response", back_populates="session", cascade="all, delete-orphan")


class Response(Base):
    """Uma resposta individual para uma pergunta específica"""
    __tablename__ = "responses"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = Column(String, ForeignKey("response_sessions.id", ondelete="CASCADE"), nullable=False, index=True)
    question_id = Column(String, ForeignKey("questions.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Valor da resposta
    value = Column(Text, nullable=True)  # Sempre texto, pode ser JSON para multiple choice
    
    # 🕐 TIMESTAMPS
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    session = relationship("ResponseSession", back_populates="responses")
    question = relationship("Question", back_populates="responses")
