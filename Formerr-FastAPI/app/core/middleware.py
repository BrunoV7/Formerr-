"""
Middlewares da Aplicação Formerr
===============================

Middlewares personalizados para tratamento de erros, logs e requests.

Autor: Equipe de Desenvolvimento
"""

from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
import time
import logging

logger = logging.getLogger(__name__)


async def error_handler_middleware(request: Request, call_next):
    """
    Middleware para tratamento global de erros
    """
    try:
        response = await call_next(request)
        return response
    except HTTPException as e:
        return JSONResponse(
            status_code=e.status_code,
            content={"error": e.detail, "status_code": e.status_code}
        )
    except Exception as e:
        logger.error(f"Erro interno: {str(e)}")
        return JSONResponse(
            status_code=500,
            content={"error": "Erro interno do servidor", "status_code": 500}
        )


async def request_middleware(request: Request, call_next):
    """
    Middleware para logging de requests
    """
    start_time = time.time()
    
    response = await call_next(request)
    
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    
    logger.info(f"{request.method} {request.url} - {response.status_code} - {process_time:.4f}s")
    
    return response