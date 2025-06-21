from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from app.auth.service import verify_jwt_token
from app.database.connection import get_db
from app.database.models import Form, FormStatus, Section, Question, ResponseSession, Response, User
from app.dependencies import get_current_user
from datetime import datetime
from sqlalchemy.exc import SQLAlchemyError
from fastapi import status as http_status
from sqlalchemy import func, cast, Date, Column
from fastapi import Request

router = APIRouter()

class FormCreateRequest(BaseModel):
    title: str
    description: Optional[str] = None
    icon: Optional[str] = None
    folder_color: Optional[str] = None

class FormCreateResponse(BaseModel):
    formId: str

class QuestionCreateRequest(BaseModel):
    type: str
    title: str
    description: Optional[str] = None
    required: bool = False
    options: Optional[dict] = None
    validation: Optional[dict] = None
    order: int = 1

class SectionCreateRequest(BaseModel):
    title: str
    description: Optional[str] = None
    order: int = 1
    questions: List[QuestionCreateRequest]

class SectionCreateResponse(BaseModel):
    sectionId: str

class QuestionUpdateRequest(BaseModel):
    id: Optional[str] = None
    type: str
    title: str
    description: Optional[str] = None
    required: bool = False
    options: Optional[dict] = None
    validation: Optional[dict] = None
    order: int = 1

class SectionUpdateRequest(BaseModel):
    title: str
    description: Optional[str] = None
    order: int = 1
    questions: List[QuestionUpdateRequest]

class FormPublishRequest(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None  # public, closed, archived, draft, private
    sections_order: Optional[List[str]] = None

class FormUpdateRequest(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None  # public, closed, archived, draft, private

class QuestionPublicResponse(BaseModel):
    id: str
    type: str
    title: str
    description: Optional[str]
    required: bool
    options: Optional[dict]
    validation: Optional[dict]
    order: int

class SectionPublicResponse(BaseModel):
    id: str
    title: str
    description: Optional[str]
    order: int
    questions: List[QuestionPublicResponse]

class FormPublicResponse(BaseModel):
    id: str
    title: str
    description: Optional[str]
    status: str
    sections: List[SectionPublicResponse]

class QuestionAnalyticsResponse(BaseModel):
    question_id: str
    title: str
    type: str
    total: int
    distribution: Optional[dict] = None

class FormAnalyticsResponse(BaseModel):
    total_responses: int
    responses_per_question: List[QuestionAnalyticsResponse]
    responses_this_month: int
    responses_this_week: int

class ResponseSessionSummary(BaseModel):
    id: str
    submitted_at: datetime
    respondent_email: Optional[str]
    respondent_ip: Optional[str]
    user_agent: Optional[str]

class AnswerDetail(BaseModel):
    question_id: str
    question_title: str
    question_type: str
    value: str

class ResponseSessionDetail(BaseModel):
    id: str
    submitted_at: datetime
    respondent_email: Optional[str]
    respondent_ip: Optional[str]
    user_agent: Optional[str]
    answers: List[AnswerDetail]

class AnswerSubmitRequest(BaseModel):
    question_id: str
    value: List[str]  # Sempre array, mesmo para single choice

class SubmitFormRequest(BaseModel):
    respondent_email: Optional[str] = None
    answers: List[AnswerSubmitRequest]

class SubmitFormResponse(BaseModel):
    session_id: str
    submitted_at: datetime

@router.post("/forms", response_model=FormCreateResponse, summary="Cria um novo formulário (rascunho)")
async def create_form(
    form_data: FormCreateRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Cria um novo formulário com status de rascunho e retorna o formId.
    """
    try:
        # Buscar o user_id correto baseado no github_id
        result = await db.execute(
            select(User.id).where(User.github_id == current_user["github_id"])
        )
        user_record = result.scalar_one_or_none()
        
        if not user_record:
            raise HTTPException(status_code=404, detail="Usuário não encontrado no banco de dados")
        
        new_form = Form(
            user_id=user_record,
            title=form_data.title,
            description=form_data.description,
            icon=form_data.icon,
            folder_color=form_data.folder_color,
            status=FormStatus.DRAFT,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(new_form)
        await db.commit()
        await db.refresh(new_form)
        return FormCreateResponse(formId=str(new_form.id))
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao criar formulário: {str(e)}")

@router.post("/forms/{form_id}/sections", response_model=SectionCreateResponse, summary="Cria uma seção com perguntas para um formulário")
async def create_section_with_questions(
    form_id: str,
    section_data: SectionCreateRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Cria uma nova seção (e suas perguntas) para um formulário.
    """
    try:
        # Cria a seção
        new_section = Section(
            form_id=form_id,
            title=section_data.title,
            description=section_data.description,
            order=section_data.order
        )
        db.add(new_section)
        await db.flush()  # Garante que new_section.id está disponível

        # Cria as perguntas
        for q in section_data.questions:
            new_question = Question(
                section_id=new_section.id,
                type=q.type,
                title=q.title,
                description=q.description,
                required=q.required,
                options=q.options,
                validation=q.validation,
                order=q.order
            )
            db.add(new_question)

        await db.commit()
        await db.refresh(new_section)
        return SectionCreateResponse(sectionId=str(new_section.id))
    except SQLAlchemyError as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao criar seção: {str(e)}")

@router.put("/sections/{section_id}", summary="Atualiza uma seção e suas perguntas")
async def update_section_and_questions(
    section_id: str,
    section_data: SectionUpdateRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Atualiza uma seção e sincroniza suas perguntas (atualiza, cria novas e remove as que não estão mais).
    """
    try:
        # Busca a seção
        result = await db.execute(select(Section).where(Section.id == section_id))
        section = result.scalar_one_or_none()
        if not section:
            raise HTTPException(status_code=404, detail="Seção não encontrada")

        # Atualiza dados da seção
        section.title = section_data.title  # type: ignore
        section.description = section_data.description  # type: ignore
        section.order = section_data.order  # type: ignore
        section.updated_at = datetime.utcnow()  # type: ignore

        # Busca perguntas existentes
        result = await db.execute(select(Question).where(Question.section_id == section_id))
        existing_questions = {str(q.id): q for q in result.scalars().all()}

        # IDs das perguntas recebidas
        received_ids = set(q.id for q in section_data.questions if q.id)
        existing_ids = set(existing_questions.keys())

        # Remover perguntas que não estão mais presentes
        for qid in existing_ids - received_ids:
            await db.delete(existing_questions[qid])

        # Atualizar ou criar perguntas
        for q in section_data.questions:
            if q.id and q.id in existing_questions:
                # Atualizar existente
                question = existing_questions[q.id]
                question.type = q.type  # type: ignore
                question.title = q.title  # type: ignore
                question.description = q.description  # type: ignore
                question.required = q.required  # type: ignore
                question.options = q.options  # type: ignore
                question.validation = q.validation  # type: ignore
                question.order = q.order  # type: ignore
                question.updated_at = datetime.utcnow()  # type: ignore
            else:
                # Criar nova
                new_question = Question(
                    section_id=section_id,
                    type=q.type,
                    title=q.title,
                    description=q.description,
                    required=q.required,
                    options=q.options,
                    validation=q.validation,
                    order=q.order
                )
                db.add(new_question)

        await db.commit()
        return {"message": "Seção e perguntas atualizadas com sucesso"}
    except SQLAlchemyError as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao atualizar seção: {str(e)}")

@router.delete("/sections/{section_id}", summary="Remove uma seção e suas perguntas")
async def delete_section(
    section_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Remove uma seção e todas as perguntas associadas.
    """
    try:
        result = await db.execute(select(Section).where(Section.id == section_id))
        section = result.scalar_one_or_none()
        if not section:
            raise HTTPException(status_code=404, detail="Seção não encontrada")
        await db.delete(section)
        await db.commit()
        return {"message": "Seção removida com sucesso"}
    except SQLAlchemyError as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao remover seção: {str(e)}")

@router.put("/forms/{form_id}/publish", summary="Publica ou atualiza configurações finais do formulário")
async def publish_form(
    form_id: str,
    data: FormPublishRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Atualiza status, título, descrição e ordem das seções do formulário.
    """
    try:
        result = await db.execute(select(Form).where(Form.id == form_id))
        form = result.scalar_one_or_none()
        if not form:
            raise HTTPException(status_code=404, detail="Formulário não encontrado")

        if data.title is not None:
            form.title = data.title  # type: ignore
        if data.description is not None:
            form.description = data.description  # type: ignore
        if data.status is not None:
            # Valida status
            if data.status not in FormStatus.__members__ and data.status not in [v.value for v in FormStatus]:
                raise HTTPException(status_code=400, detail="Status inválido")
            # Permite tanto string quanto enum
            form.status = FormStatus[data.status.upper()] if data.status.upper() in FormStatus.__members__ else FormStatus(data.status)  # type: ignore
        form.updated_at = datetime.utcnow()  # type: ignore

        # Atualiza ordem das seções se fornecido
        if data.sections_order:
            # Busca seções do formulário
            result = await db.execute(select(Section).where(Section.form_id == form_id))
            sections = {str(s.id): s for s in result.scalars().all()}
            for idx, sec_id in enumerate(data.sections_order, start=1):
                if sec_id in sections:
                    sections[sec_id].order = idx  # type: ignore
                    sections[sec_id].updated_at = datetime.utcnow()  # type: ignore

        await db.commit()
        return {"message": "Formulário atualizado com sucesso"}
    except SQLAlchemyError as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao atualizar formulário: {str(e)}")

@router.put("/forms/{form_id}", summary="Atualiza informações básicas do formulário")
async def update_form(
    form_id: str,
    data: FormUpdateRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Atualiza título, descrição e status do formulário.
    """
    try:
        result = await db.execute(select(Form).where(Form.id == form_id))
        form = result.scalar_one_or_none()
        if not form:
            raise HTTPException(status_code=404, detail="Formulário não encontrado")

        # Atualizar campos se fornecidos
        if data.title is not None:
            form.title = data.title  # type: ignore
        if data.description is not None:
            form.description = data.description  # type: ignore
        if data.status is not None:
            # Valida status
            valid_statuses = ['draft', 'public', 'closed', 'archived', 'private']
            if data.status not in valid_statuses:
                raise HTTPException(status_code=400, detail=f"Status inválido. Use: {', '.join(valid_statuses)}")
            form.status = FormStatus(data.status)  # type: ignore
        
        form.updated_at = datetime.utcnow()  # type: ignore

        await db.commit()
        await db.refresh(form)

        return {"message": "Formulário atualizado com sucesso"}
    except SQLAlchemyError as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao atualizar formulário: {str(e)}")

@router.get("/forms/{form_id}/public", response_model=FormPublicResponse, summary="Exibe formulário público para preenchimento")
async def get_public_form(
    form_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Retorna o formulário completo (se status for public), incluindo seções e perguntas ordenadas.
    """
    result = await db.execute(select(Form).where(Form.id == form_id))
    form = result.scalar_one_or_none()
    if not form or form.status.value != "public":
        raise HTTPException(status_code=http_status.HTTP_404_NOT_FOUND, detail="Formulário não encontrado ou não está público")

    # Busca seções ordenadas
    result = await db.execute(select(Section).where(Section.form_id == form_id).order_by(Section.order))
    sections = result.scalars().all()
    section_list = []
    for section in sections:
        # Busca perguntas ordenadas
        q_result = await db.execute(select(Question).where(Question.section_id == section.id).order_by(Question.order))
        questions = q_result.scalars().all()
        section_list.append(SectionPublicResponse(
            id=str(section.id),
            title=str(section.title),
            description=str(section.description) if section.description is not None else None,
            order=int(section.order) if not isinstance(section.order, Column) and section.order is not None else 0,
            questions=[
                QuestionPublicResponse(
                    id=str(q.id),
                    type=str(q.type),
                    title=str(q.title),
                    description=str(q.description) if q.description is not None else None,
                    required=bool(q.required),
                    options=dict(q.options) if isinstance(q.options, dict) else None,
                    validation=dict(q.validation) if isinstance(q.validation, dict) else None,
                    order=int(q.order) if not isinstance(q.order, Column) and q.order is not None else 0
                ) for q in questions
            ]
        ))
    return FormPublicResponse(
        id=str(form.id),
        title=str(form.title),
        description=str(form.description) if form.description is not None else None,
        status=form.status.value,
        sections=section_list
    )

@router.get("/forms/{form_id}/analytics", response_model=FormAnalyticsResponse, summary="Estatísticas agregadas das respostas do formulário")
async def get_form_analytics(
    form_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Retorna estatísticas agregadas das respostas do formulário.
    """
    # Busca total de respostas
    total_responses_query = select(func.count()).select_from(ResponseSession).where(ResponseSession.form_id == form_id)
    total_responses = (await db.execute(total_responses_query)).scalar() or 0

    # Respostas este mês e esta semana
    from datetime import datetime, timedelta
    now = datetime.utcnow()
    start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    start_of_week = now - timedelta(days=now.weekday())
    start_of_week = start_of_week.replace(hour=0, minute=0, second=0, microsecond=0)

    responses_month_query = select(func.count()).select_from(ResponseSession).where(
        ResponseSession.form_id == form_id,
        ResponseSession.submitted_at >= start_of_month
    )
    responses_this_month = (await db.execute(responses_month_query)).scalar() or 0

    responses_week_query = select(func.count()).select_from(ResponseSession).where(
        ResponseSession.form_id == form_id,
        ResponseSession.submitted_at >= start_of_week
    )
    responses_this_week = (await db.execute(responses_week_query)).scalar() or 0

    # Busca perguntas do formulário
    result = await db.execute(select(Section).where(Section.form_id == form_id).order_by(Section.order))
    sections = result.scalars().all()
    question_ids = []
    questions_map = {}
    for section in sections:
        q_result = await db.execute(select(Question).where(Question.section_id == section.id).order_by(Question.order))
        for q in q_result.scalars().all():
            question_ids.append(q.id)
            questions_map[q.id] = q

    responses_per_question = []
    for qid in question_ids:
        q = questions_map[qid]
        # Total de respostas para a pergunta
        total_q_query = select(func.count()).select_from(Response).where(Response.question_id == qid)
        total_q = (await db.execute(total_q_query)).scalar() or 0
        
        # Gerar distribuição para todos os tipos de pergunta
        distribution = None
        if total_q > 0:
            # Busca todas as respostas e conta a distribuição
            dist_query = select(Response.value, func.count()).where(Response.question_id == qid).group_by(Response.value)
            dist_result = await db.execute(dist_query)
            distribution = {row[0]: row[1] for row in dist_result.all()}
        
        responses_per_question.append(QuestionAnalyticsResponse(
            question_id=qid,
            title=q.title,
            type=q.type,
            total=total_q,
            distribution=distribution
        ))

    return FormAnalyticsResponse(
        total_responses=total_responses,
        responses_per_question=responses_per_question,
        responses_this_month=responses_this_month,
        responses_this_week=responses_this_week
    )

@router.get("/forms/{form_id}/responses", response_model=List[ResponseSessionSummary], summary="Lista sessões de respostas do formulário")
async def list_response_sessions(
    form_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Lista sessões de respostas (envios) do formulário.
    """
    result = await db.execute(
        select(ResponseSession).where(ResponseSession.form_id == form_id).order_by(ResponseSession.submitted_at.desc())
    )
    sessions = result.scalars().all()
    return [
        ResponseSessionSummary(
            id=str(s.id),
            submitted_at=s.submitted_at if isinstance(s.submitted_at, datetime) else datetime.utcnow(),
            respondent_email=str(s.respondent_email) if s.respondent_email is not None else None,
            respondent_ip=str(s.respondent_ip) if s.respondent_ip is not None else None,
            user_agent=str(s.user_agent) if s.user_agent is not None else None
        ) for s in sessions
    ]

@router.get("/responses/{answer_session_id}", response_model=ResponseSessionDetail, summary="Detalha uma sessão de resposta individual")
async def get_response_session_detail(
    answer_session_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Retorna dados da sessão e respostas associadas às perguntas.
    """
    # Busca sessão
    result = await db.execute(select(ResponseSession).where(ResponseSession.id == answer_session_id))
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Sessão de resposta não encontrada")
    # Busca respostas
    result = await db.execute(select(Response).where(Response.session_id == answer_session_id))
    answers = result.scalars().all()
    # Busca perguntas para mapear título/tipo
    question_ids = [a.question_id for a in answers]
    if question_ids:
        q_result = await db.execute(select(Question).where(Question.id.in_(question_ids)))
        questions_map = {str(q.id): q for q in q_result.scalars().all()}
    else:
        questions_map = {}
    return ResponseSessionDetail(
        id=str(session.id),
        submitted_at=session.submitted_at if isinstance(session.submitted_at, datetime) else datetime.utcnow(),
        respondent_email=str(session.respondent_email) if session.respondent_email is not None else None,
        respondent_ip=str(session.respondent_ip) if session.respondent_ip is not None else None,
        user_agent=str(session.user_agent) if session.user_agent is not None else None,
        answers=[
            AnswerDetail(
                question_id=str(a.question_id),
                question_title=str(questions_map[str(a.question_id)].title) if str(a.question_id) in questions_map and questions_map[str(a.question_id)].title is not None else "",
                question_type=str(questions_map[str(a.question_id)].type) if str(a.question_id) in questions_map and questions_map[str(a.question_id)].type is not None else "",
                value=str(a.value)
            ) for a in answers
        ]
    )

@router.post("/forms/{form_id}/submit", response_model=SubmitFormResponse, summary="Submissão pública de respostas do formulário")
async def submit_form_response(
    form_id: str,
    data: SubmitFormRequest,
    request: Request,  # Usa o tipo correto do starlette
    db: AsyncSession = Depends(get_db)
):
    """
    Submissão pública de respostas do formulário. Cria ResponseSession e Responses.
    """
    from json import dumps
    
    try:
        # Cria sessão de resposta
        user_agent = request.headers.get("user-agent")
        respondent_ip = request.client.host if request.client else None
        session = ResponseSession(
            form_id=form_id,
            respondent_email=data.respondent_email,
            respondent_ip=respondent_ip,
            user_agent=user_agent
        )
        db.add(session)
        await db.flush()  # Garante session.id
        # Cria respostas
        for ans in data.answers:
            value_json = dumps(ans.value)  # Sempre serializa como JSON string
            response = Response(
                session_id=session.id,
                question_id=ans.question_id,
                value=value_json
            )
            db.add(response)
        await db.commit()
        await db.refresh(session)
        return SubmitFormResponse(session_id=str(session.id), submitted_at=session.submitted_at if isinstance(session.submitted_at, datetime) else datetime.utcnow())
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao submeter respostas: {str(e)}")

@router.delete("/forms/{form_id}", summary="Remove um formulário e todos os seus dados associados")
async def delete_form(
    form_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Remove um formulário e todos os seus dados associados (seções, perguntas, respostas).
    
    Args:
        form_id: ID do formulário a ser removido
        current_user: Usuário autenticado
        db: Sessão do banco de dados
    
    Returns:
        Mensagem de confirmação
    """
    try:
        print(f"🔍 DEBUG - Tentando deletar formulário: {form_id}")
        print(f"🔍 DEBUG - Current user github_id: {current_user['github_id']}")
        
        # Buscar o user_id correto baseado no github_id
        result = await db.execute(
            select(User.id).where(User.github_id == current_user["github_id"])
        )
        user_record = result.scalar_one_or_none()
        
        if not user_record:
            raise HTTPException(status_code=404, detail="Usuário não encontrado no banco de dados")
        
        print(f"🔍 DEBUG - User ID encontrado: {user_record}")
        
        # Busca o formulário
        result = await db.execute(
            select(Form).where(
                Form.id == form_id,
                Form.user_id == user_record
            )
        )
        form = result.scalar_one_or_none()
        
        print(f"🔍 DEBUG - Formulário encontrado: {form is not None}")
        if form:
            print(f"🔍 DEBUG - Form.user_id: {form.user_id}")
        
        if not form:
            raise HTTPException(
                status_code=404,
                detail="Formulário não encontrado ou você não tem permissão para removê-lo"
            )
        
        print(f"🔍 DEBUG - Tentando deletar formulário do banco...")
        # Remove o formulário (cascade irá remover seções, perguntas e respostas)
        await db.delete(form)
        await db.commit()
        print(f"🔍 DEBUG - Formulário deletado com sucesso!")
        
        return {"message": "Formulário removido com sucesso"}
        
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        print(f"❌ ERRO ao remover formulário: {str(e)}")
        print(f"❌ Tipo do erro: {type(e).__name__}")
        import traceback
        print(f"❌ Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao remover formulário: {str(e)}"
        )

@router.get("/forms/{form_id}/sections", summary="Lista todas as seções de um formulário")
async def get_form_sections(
    form_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Retorna todas as seções de um formulário com suas perguntas.
    """
    try:
        # Verificar se o usuário tem acesso ao formulário
        user_result = await db.execute(
            select(User.id).where(User.github_id == current_user["github_id"])
        )
        user_record = user_result.scalar_one_or_none()
        
        if not user_record:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
        
        form_result = await db.execute(
            select(Form).where(Form.id == form_id, Form.user_id == user_record)
        )
        form = form_result.scalar_one_or_none()
        
        if not form:
            raise HTTPException(status_code=404, detail="Formulário não encontrado")
        
        # Buscar seções com perguntas
        sections_result = await db.execute(
            select(Section).where(Section.form_id == form_id).order_by(Section.order)
        )
        sections = sections_result.scalars().all()
        
        sections_data = []
        for section in sections:
            questions_result = await db.execute(
                select(Question).where(Question.section_id == section.id).order_by(Question.order)
            )
            questions = questions_result.scalars().all()
            
            questions_data = [
                {
                    "id": str(q.id),
                    "type": q.type,
                    "title": q.title,
                    "description": q.description,
                    "required": q.required,
                    "options": q.options or {},
                    "validation": q.validation or {},
                    "order": q.order
                }
                for q in questions
            ]
            
            sections_data.append({
                "id": str(section.id),
                "title": section.title,
                "description": section.description,
                "order": section.order,
                "questions": questions_data
            })
        
        return {
            "form_id": form_id,
            "sections": sections_data
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao buscar seções: {str(e)}")

@router.get("/forms/{form_id}", summary="Busca dados básicos de um formulário")
async def get_form(
    form_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Busca os dados básicos de um formulário específico.
    """
    try:
        # Verificar se o usuário tem acesso ao formulário
        user_result = await db.execute(
            select(User.id).where(User.github_id == current_user["github_id"])
        )
        user_record = user_result.scalar_one_or_none()
        
        if not user_record:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
        
        form_result = await db.execute(
            select(Form).where(Form.id == form_id, Form.user_id == user_record)
        )
        form = form_result.scalar_one_or_none()
        
        if not form:
            raise HTTPException(status_code=404, detail="Formulário não encontrado")
        
        return {
            "id": str(form.id),
            "title": form.title,
            "description": form.description,
            "icon": form.icon,
            "color": form.folder_color,
            "status": form.status.value if form.status else "draft",
            "created_at": form.created_at,
            "updated_at": form.updated_at
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao buscar formulário: {str(e)}")

@router.get("/sections/{section_id}", summary="Busca dados de uma seção específica com suas perguntas")
async def get_section(
    section_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Busca os dados de uma seção específica com suas perguntas.
    """
    try:
        # Buscar a seção
        section_result = await db.execute(
            select(Section).where(Section.id == section_id)
        )
        section = section_result.scalar_one_or_none()
        
        if not section:
            raise HTTPException(status_code=404, detail="Seção não encontrada")
        
        # Verificar se o usuário tem acesso ao formulário da seção
        user_result = await db.execute(
            select(User.id).where(User.github_id == current_user["github_id"])
        )
        user_record = user_result.scalar_one_or_none()
        
        if not user_record:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
        
        form_result = await db.execute(
            select(Form).where(Form.id == section.form_id, Form.user_id == user_record)
        )
        form = form_result.scalar_one_or_none()
        
        if not form:
            raise HTTPException(status_code=404, detail="Formulário não encontrado ou não autorizado")
        
        # Buscar perguntas da seção
        questions_result = await db.execute(
            select(Question).where(Question.section_id == section_id).order_by(Question.order)
        )
        questions = questions_result.scalars().all()
        
        questions_data = [
            {
                "id": str(q.id),
                "type": q.type,
                "title": q.title,
                "description": q.description,
                "required": q.required,
                "options": q.options or {},
                "validation": q.validation or {},
                "order": q.order
            }
            for q in questions
        ]
        
        return {
            "id": str(section.id),
            "title": section.title,
            "description": section.description,
            "order": section.order,
            "questions": questions_data
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao buscar seção: {str(e)}")