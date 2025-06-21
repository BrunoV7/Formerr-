from typing import List, Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from sqlalchemy import func, and_, or_
from datetime import datetime
import uuid

from app.database.models import User, Form, FormResponse, FormAnalytics
from app.forms.models import FormCreate, FormUpdate, Form as FormSchema
from app.database.connection import get_db


class UserService:
    """Service para operações com usuários"""

    @staticmethod
    async def get_or_create_user(db: AsyncSession, github_data: Dict[str, Any]) -> User:
        """Busca ou cria usuário baseado nos dados do GitHub"""
        # Buscar usuário existente
        result = await db.execute(
            select(User).where(User.github_id == github_data["github_id"])
        )
        user = result.scalar_one_or_none()

        if user:
            # Atualizar dados do usuário existente
            user.name = github_data.get("name")
            user.email = github_data.get("email")
            user.avatar_url = github_data.get("avatar_url")
            user.last_login = datetime.utcnow()
            user.updated_at = datetime.utcnow()
        else:
            # Criar novo usuário
            user = User(
                github_id=github_data["github_id"],
                username=github_data["username"],
                name=github_data.get("name"),
                email=github_data.get("email"),
                avatar_url=github_data.get("avatar_url"),
                github_url=github_data.get("github_url"),
                created_at=datetime.utcnow(),
                last_login=datetime.utcnow()
            )
            db.add(user)

        await db.commit()
        await db.refresh(user)
        return user


class FormsService:
    """Service para operações com formulários"""

    @staticmethod
    def generate_form_id() -> str:
        """Gera ID único para formulário"""
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        unique_id = str(uuid.uuid4())[:8]
        return f"form_{timestamp}_{unique_id}"

    @staticmethod
    async def create_form(db: AsyncSession, form_data: FormCreate, owner_id: int) -> Form:
        """Cria novo formulário"""
        form_id = FormsService.generate_form_id()

        # Processar sections (novo campo estruturado)
        sections = getattr(form_data, 'sections', None) or []
        
        # Compatibilidade: se ainda usa questions/fields, migra para sections
        if hasattr(form_data, 'questions') and form_data.questions:
            # Converter questions antigas para formato sections
            sections = [{
                "id": "default_section",
                "title": "Perguntas",
                "description": "",
                "order": 1,
                "questions": [q.dict() for q in form_data.questions]
            }]
        elif hasattr(form_data, 'fields') and form_data.fields:
            # Converter fields para sections
            sections = [{
                "id": "default_section", 
                "title": "Campos",
                "description": "",
                "order": 1,
                "questions": form_data.fields
            }]

        # Criar objeto Form com novo modelo
        form = Form(
            id=form_id,
            title=form_data.title,
            description=form_data.description,
            user_id=owner_id,  # Campo principal
            max_responses=getattr(form_data, 'max_responses', None),
            icon=getattr(form_data, 'icon', None),
            banner_image_url=getattr(form_data, 'banner_image_url', None),
            is_private=getattr(form_data, 'is_private', False),
            authorized_emails=getattr(form_data, 'authorized_emails', None),
            expires_at=getattr(form_data, 'expires_at', None),
            sections=sections,  # Novo campo estruturado
            folder_color=getattr(form_data, 'folder_color', None),
            folder_color_dark=getattr(form_data, 'folder_color_dark', None),
            status="draft",  # Estado inicial
            is_published=getattr(form_data, 'is_published', False),  # Campo correto
            allow_multiple_submissions=getattr(form_data, 'allow_multiple_submissions', True),
            created_at=datetime.utcnow(),
            view_count=0,
            response_count=0,
            completion_rate=0.0,
            avg_completion_time=0
        )

        db.add(form)
        await db.commit()
        await db.refresh(form)

        return form

    @staticmethod
    async def get_user_forms(db: AsyncSession, owner_id: int, limit: int = 50) -> List[Form]:
        """Lista formulários do usuário"""
        result = await db.execute(
            select(Form)
            .where(Form.user_id == owner_id)  # Mudou de owner_id para user_id
            .order_by(Form.created_at.desc())
            .limit(limit)
        )
        return result.scalars().all()

    @staticmethod
    async def get_form_by_id(db: AsyncSession, form_id: str, owner_id: Optional[int] = None) -> Optional[Form]:
        """Busca formulário por ID"""
        query = select(Form).where(Form.id == form_id)

        if owner_id is not None:
            query = query.where(Form.user_id == owner_id)  # Mudou de owner_id para user_id

        result = await db.execute(query)
        return result.scalar_one_or_none()

    @staticmethod
    async def get_public_form(db: AsyncSession, form_id: str) -> Optional[Form]:
        """Busca formulário público"""
        result = await db.execute(
            select(Form)
            .options(selectinload(Form.owner))
            .where(and_(Form.id == form_id, Form.is_published == True))
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def update_form(db: AsyncSession, form_id: str, update_data: FormUpdate, owner_id: int) -> Optional[Form]:
        """Atualiza formulário"""
        result = await db.execute(
            select(Form).where(and_(Form.id == form_id, Form.user_id == owner_id))  # Mudou para user_id
        )
        form = result.scalar_one_or_none()

        if not form:
            return None

        # Atualizar campos fornecidos
        update_dict = update_data.dict(exclude_unset=True)

        for field, value in update_dict.items():
            # Mapeamento de compatibilidade
            if field == "questions":
                field = "fields"  # Mapeia questions para fields
            elif field == "public":
                field = "is_published"  # Mapeia public para is_published
            
            if field in ["fields", "sections", "settings"] and value is not None:
                # Converter Pydantic models para dict se necessário
                if hasattr(value, 'dict'):
                    value = value.dict()
                elif isinstance(value, list) and value and hasattr(value[0], 'dict'):
                    value = [item.dict() for item in value]

            setattr(form, field, value)

        # Set published_at timestamp when form is published
        if 'is_published' in update_dict and update_dict['is_published'] and not form.published_at:
            form.published_at = datetime.utcnow()

        form.updated_at = datetime.utcnow()

        await db.commit()
        await db.refresh(form)

        return form

    @staticmethod
    async def delete_form(db: AsyncSession, form_id: str, owner_id: int) -> bool:
        """Deleta formulário"""
        result = await db.execute(
            select(Form).where(and_(Form.id == form_id, Form.user_id == owner_id))  # Mudou para user_id
        )
        form = result.scalar_one_or_none()

        if not form:
            return False

        await db.delete(form)
        await db.commit()
        return True

    @staticmethod
    async def increment_response_count(db: AsyncSession, form_id: str) -> None:
        """Incrementa contador de respostas"""
        result = await db.execute(
            select(Form).where(Form.id == form_id)
        )
        form = result.scalar_one_or_none()

        if form:
            form.response_count += 1
            form.last_response_at = datetime.utcnow()
            await db.commit()


class ResponsesService:
    """Service para operações com respostas de formulários"""

    @staticmethod
    def generate_response_id() -> str:
        """Gera ID único para resposta"""
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        unique_id = str(uuid.uuid4())[:8]
        return f"resp_{timestamp}_{unique_id}"

    @staticmethod
    async def create_response(
            db: AsyncSession,
            form_id: str,
            responses: Dict[str, Any],
            respondent_data: Optional[Dict[str, Any]] = None
    ) -> FormResponse:
        """Cria nova resposta COM WEBHOOK TRIGGER"""
        response_id = ResponsesService.generate_response_id()

        form_response = FormResponse(
            id=response_id,
            form_id=form_id,
            responses=responses,
            respondent_email=respondent_data.get("email") if respondent_data else None,
            respondent_id=respondent_data.get("respondent_id") if respondent_data else None,
            completion_time=respondent_data.get("completion_time") if respondent_data else None,
            ip_address=respondent_data.get("ip_address") if respondent_data else None,
            user_agent=respondent_data.get("user_agent") if respondent_data else None,
            started_at=respondent_data.get("started_at") if respondent_data else None,
            completed_at=datetime.utcnow(),
            created_at=datetime.utcnow()
        )

        db.add(form_response)
        await db.commit()
        await db.refresh(form_response)

        # Incrementar contador no formulário
        await FormsService.increment_response_count(db, form_id)

        # 🔥 BEAST MODE: Disparar webhooks
        from app.webhooks.service import webhook_service
        from app.webhooks.models import WebhookEvent

        webhook_payload = {
            "response_id": form_response.id,
            "respondent_email": form_response.respondent_email,
            "responses": form_response.responses,
            "completed_at": form_response.completed_at.isoformat(),
            "total_responses": len(form_response.responses)
        }

        # Disparar webhooks em background (não bloquear resposta)
        try:
            await webhook_service.trigger_webhooks(
                db=db,
                form_id=form_id,
                event=WebhookEvent.RESPONSE_CREATED,
                payload=webhook_payload
            )
        except Exception as e:
            print(f"🚨 Erro ao disparar webhooks: {e}")
            # Não falhar a resposta por causa de webhook

        return form_response

    @staticmethod
    async def get_form_responses(
            db: AsyncSession,
            form_id: str,
            owner_id: int,
            limit: int = 100
    ) -> List[FormResponse]:
        """Lista respostas de um formulário"""
        # Verificar se o usuário é dono do formulário
        form_result = await db.execute(
            select(Form).where(and_(Form.id == form_id, Form.user_id == owner_id))
        )
        form = form_result.scalar_one_or_none()

        if not form:
            return []

        result = await db.execute(
            select(FormResponse)
            .where(FormResponse.form_id == form_id)
            .order_by(FormResponse.completed_at.desc())
            .limit(limit)
        )
        return result.scalars().all()

    @staticmethod
    async def get_response_stats(db: AsyncSession, form_id: str, owner_id: int) -> Dict[str, Any]:
        """Estatísticas de respostas"""
        # Verificar ownership
        form_result = await db.execute(
            select(Form).where(and_(Form.id == form_id, Form.user_id == owner_id))
        )
        form = form_result.scalar_one_or_none()

        if not form:
            return {}

        # Contar respostas
        total_result = await db.execute(
            select(func.count(FormResponse.id)).where(FormResponse.form_id == form_id)
        )
        total_responses = total_result.scalar()

        # Respostas por dia (últimos 7 dias)
        # TODO: Implementar query mais complexa para estatísticas

        return {
            "form_id": form_id,
            "total_responses": total_responses,
            "last_response": form.last_response_at,
            "response_rate": "TODO: calcular taxa"
        }


# Instâncias dos services
user_service = UserService()
forms_service = FormsService()
responses_service = ResponsesService()
submissions_service = responses_service  # Alias para compatibilidade