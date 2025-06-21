#!/usr/bin/env python3
"""
Script para criar/recriar todas as tabelas do banco de dados
============================================================

Este script cria todas as tabelas necessárias para o funcionamento da aplicação.
Execute quando precisar resetar o banco ou criar as tabelas pela primeira vez.

Uso: python create_tables.py
"""

import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from app.config import settings
from app.database.connection import Base
from app.database.models import *  # Importa todos os models
import ssl

async def create_tables():
    """Cria todas as tabelas no banco de dados"""
    
    print("🔨 Criando tabelas do banco de dados...")
    
    # SSL context para DigitalOcean
    ssl_context = ssl.create_default_context()
    ssl_context.check_hostname = False
    ssl_context.verify_mode = ssl.CERT_NONE
    
    # Engine para criação das tabelas
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=True,  # Mostra os SQLs executados
        connect_args={
            "ssl": ssl_context,
            "server_settings": {
                "application_name": "formerr_table_creation",
            }
        }
    )
    
    try:
        async with engine.begin() as conn:
            # Drop all tables (cuidado!)
            print("⚠️  Removendo tabelas existentes...")
            await conn.run_sync(Base.metadata.drop_all)
            
            # Create all tables
            print("✅ Criando novas tabelas...")
            await conn.run_sync(Base.metadata.create_all)
            
        print("🎉 Tabelas criadas com sucesso!")
        print("\nTabelas criadas:")
        for table_name in Base.metadata.tables.keys():
            print(f"  - {table_name}")
            
    except Exception as e:
        print(f"❌ Erro ao criar tabelas: {e}")
        raise
    finally:
        await engine.dispose()

if __name__ == "__main__":
    asyncio.run(create_tables())
