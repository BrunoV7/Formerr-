"""
Formerr API - Sistema de Criação e Gerenciamento de Formulários
=============================================================

Fresh start! Sistema limpo focado em:
- Autenticação GitHub
- Dashboard com estatísticas
- Criação de formulários (draft → sections → publish)
- Estrutura normalizada: Form → Section → Question
- Respostas: ResponseSession → Response

"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.sessions import SessionMiddleware
from app.core.middleware import error_handler_middleware, request_middleware
from app.auth.routes import router as auth_router
from app.dashboard.routes import router as dashboard_router
from app.forms.routes import router as forms_router
from app.config import settings
from app.database.connection import engine
from sqlalchemy import text

# Criar a aplicação FastAPI
app = FastAPI(
    title="Formerr API",
    description="Sistema de criação e gerenciamento de formulários",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configurar CORS - usando variável de ambiente
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Adicionar SessionMiddleware para OAuth
app.add_middleware(
    SessionMiddleware,
    secret_key=settings.SESSION_SECRET
)

# Adicionar middlewares personalizados
app.middleware("http")(error_handler_middleware)

# Health check endpoint for Docker/Kubernetes
@app.get("/health")
async def health_check():
    """
    Health check endpoint for monitoring and load balancers
    """
    try:
        # Test database connection
        async with engine.begin() as conn:
            await conn.execute(text("SELECT 1"))
        
        return {
            "status": "healthy",
            "service": "formerr-api",
            "version": "1.0.0",
            "database": "connected"
        }
    except Exception as e:
        return {
            "status": "unhealthy", 
            "service": "formerr-api",
            "version": "1.0.0",
            "database": "disconnected",
            "error": str(e)
        }

# Incluir rotas
app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(dashboard_router, prefix="/dashboard", tags=["dashboard"])
app.include_router(forms_router, tags=["forms"])

@app.get("/")
async def root():
    """Endpoint raiz da API"""
    return {
        "message": "Formerr API v2.0 - Fresh Start!",
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "docs": "/docs",
        "status": "operational"
    }

@app.get("/status_check")
async def status_check():
    """Status detalhado da API e recursos principais"""
    db_status = "unknown"
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
            db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"
    # Esconde senha do database_url
    db_url_safe = settings.DATABASE_URL
    if "@" in db_url_safe:
        db_url_safe = db_url_safe.split("@", 1)[-1]
        db_url_safe = "***@" + db_url_safe
    return {
        "status": "ok",
        "version": settings.APP_VERSION,
        "environment": getattr(settings, "ENVIRONMENT", "unknown"),
        "database_url": db_url_safe,
        "database_status": db_status,
        "resources": [
            "/auth/*",
            "/dashboard/*",
            "/forms/*",
            "/forms/{form_id}/sections",
            "/forms/{form_id}/publish",
            "/forms/{form_id}/public",
            "/forms/{form_id}/analytics",
            "/forms/{form_id}/responses",
            "/responses/{answer_session_id}",
            "/forms/{form_id}/submit"
        ]
    }

@app.on_event("startup")
async def startup_report():
    print("\n==============================")
    print(f"🚀 Formerr API v{settings.APP_VERSION} - Ambiente: {getattr(settings, 'ENVIRONMENT', 'unknown')}")
    # Testa conexão com o banco
    from sqlalchemy import text
    db_status = "unknown"
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
            db_status = "CONNECTED"
    except Exception as e:
        db_status = f"ERROR: {str(e)}"
    print(f"📦 Database: {settings.DATABASE_URL.split('@')[-1] if '@' in settings.DATABASE_URL else settings.DATABASE_URL}")
    print(f"   Status: {db_status}")
    print("🔗 Endpoints principais:")
    print("   /auth/*")
    print("   /dashboard/*")
    print("   /forms/*")
    print("   /forms/{form_id}/sections")
    print("   /forms/{form_id}/publish")
    print("   /forms/{form_id}/public")
    print("   /forms/{form_id}/analytics")
    print("   /forms/{form_id}/responses")
    print("   /responses/{answer_session_id}")
    print("   /forms/{form_id}/submit")
    print("==============================\n")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
