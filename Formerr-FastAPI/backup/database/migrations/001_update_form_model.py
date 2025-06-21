"""
Migração para o Novo Modelo de Formulários
=========================================

Esta migração atualiza a estrutura da tabela 'forms' para incluir:
- Customização visual (icon, folder_color, folder_color_dark)
- Campos unificados (fields ao invés de questions/sections separados)
- Melhores configurações (is_active, is_published, etc.)
- Analytics integrado (view_count, completion_rate)

Execute este script quando estiver pronto para migrar o banco de dados.
"""

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.database.connection import get_db

# Script SQL para migração (exemplo - ajuste conforme sua configuração de DB)
MIGRATION_SQL = """
-- Adicionar novas colunas à tabela forms
ALTER TABLE forms 
ADD COLUMN IF NOT EXISTS icon VARCHAR(10),
ADD COLUMN IF NOT EXISTS folder_color VARCHAR(20),
ADD COLUMN IF NOT EXISTS folder_color_dark VARCHAR(20),
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS allow_multiple_submissions BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS require_authentication BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS fields JSON,
ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS completion_rate FLOAT DEFAULT 0.0;

-- Migrar dados existentes
UPDATE forms 
SET 
    is_active = TRUE,
    is_published = COALESCE(public, FALSE),
    allow_multiple_submissions = TRUE,
    require_authentication = FALSE,
    fields = questions,
    view_count = COALESCE(view_count, 0),
    completion_rate = 0.0
WHERE fields IS NULL;

-- Renomear colunas se necessário (ajuste conforme sua situação)
-- ALTER TABLE forms RENAME COLUMN owner_id TO user_id;

-- Remover colunas antigas após verificação (cuidado!)
-- ALTER TABLE forms DROP COLUMN IF EXISTS questions;
-- ALTER TABLE forms DROP COLUMN IF EXISTS sections;
-- ALTER TABLE forms DROP COLUMN IF EXISTS public;
"""

async def run_migration():
    """
    Executa a migração do banco de dados
    ⚠️ CUIDADO: Execute apenas em ambiente de desenvolvimento/teste primeiro!
    """
    print("🔄 Iniciando migração do modelo de formulários...")
    
    async for db in get_db():
        try:
            # Execute a migração
            await db.execute(text(MIGRATION_SQL))
            await db.commit()
            print("✅ Migração executada com sucesso!")
            
        except Exception as e:
            await db.rollback()
            print(f"❌ Erro na migração: {e}")
            raise
        finally:
            await db.close()

if __name__ == "__main__":
    import asyncio
    
    print("⚠️  AVISO: Esta migração irá alterar a estrutura do banco de dados!")
    print("📋 Certifique-se de fazer backup antes de executar em produção.")
    
    confirm = input("Deseja continuar? (sim/não): ")
    if confirm.lower() in ['sim', 's', 'yes', 'y']:
        asyncio.run(run_migration())
    else:
        print("Migração cancelada.")
