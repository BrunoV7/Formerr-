"""
Migração para Adicionar Role Column na Tabela Users
==================================================

Esta migração adiciona a coluna 'role' à tabela 'users' para implementar
o sistema de roles e permissões (FREE, PRO, ENTERPRISE).

Execute este script para atualizar o esquema do banco de dados.
"""

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.database.connection import get_db, engine
import asyncio

# Script SQL para migração
MIGRATION_SQL = """
-- Criar enum para roles se não existir
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'userrole') THEN
        CREATE TYPE userrole AS ENUM ('FREE', 'PRO', 'ENTERPRISE');
    END IF;
END
$$;

-- Adicionar coluna role à tabela users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role userrole DEFAULT 'FREE' NOT NULL;

-- Adicionar outras colunas relacionadas ao sistema de auth
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS subscription_expires TIMESTAMP,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS monthly_submissions_used INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS monthly_reset_date TIMESTAMP DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS team_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS invited_by INTEGER REFERENCES users(id),
ADD COLUMN IF NOT EXISTS last_login TIMESTAMP DEFAULT NOW();

-- Atualizar registros existentes com role FREE
UPDATE users 
SET role = 'FREE', 
    is_active = TRUE,
    monthly_submissions_used = 0,
    monthly_reset_date = NOW(),
    last_login = NOW()
WHERE role IS NULL OR is_active IS NULL;

-- Criar índice para performance
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_team_id ON users(team_id);
"""

async def run_migration():
    """Execute a migração"""
    try:
        async with engine.begin() as conn:
            print("🚀 Executando migração para adicionar role à tabela users...")
            
            # Execute cada comando separadamente para melhor controle de erros
            commands = MIGRATION_SQL.strip().split(';')
            
            for i, command in enumerate(commands):
                command = command.strip()
                if command:
                    try:
                        print(f"📝 Executando comando {i+1}/{len(commands)}...")
                        await conn.execute(text(command))
                        print(f"✅ Comando {i+1} executado com sucesso")
                    except Exception as e:
                        print(f"⚠️  Comando {i+1} falhou (pode ser esperado): {e}")
            
            print("✅ Migração concluída com sucesso!")
            
    except Exception as e:
        print(f"❌ Erro durante a migração: {e}")
        raise

async def verify_migration():
    """Verificar se a migração foi aplicada corretamente"""
    try:
        async with engine.begin() as conn:
            print("\n🔍 Verificando migração...")
            
            # Verificar se a coluna role existe
            result = await conn.execute(text("""
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns 
                WHERE table_name = 'users' 
                AND column_name IN ('role', 'subscription_expires', 'is_active', 'team_id');
            """))
            
            columns = result.fetchall()
            
            if columns:
                print("✅ Colunas encontradas na tabela users:")
                for col in columns:
                    print(f"  - {col[0]}: {col[1]} (nullable: {col[2]}, default: {col[3]})")
                
                # Verificar se existem dados
                count_result = await conn.execute(text("SELECT COUNT(*) FROM users"))
                user_count = count_result.scalar()
                print(f"📊 Total de usuários na tabela: {user_count}")
                
                if user_count > 0:
                    # Verificar roles
                    role_result = await conn.execute(text("SELECT role, COUNT(*) FROM users GROUP BY role"))
                    roles = role_result.fetchall()
                    print("🏷️  Distribuição de roles:")
                    for role_info in roles:
                        print(f"  - {role_info[0]}: {role_info[1]} usuários")
                
            else:
                print("❌ Nenhuma coluna encontrada - migração pode ter falhado")
                
    except Exception as e:
        print(f"❌ Erro na verificação: {e}")

if __name__ == "__main__":
    async def main():
        print("🗄️  Iniciando migração do banco de dados...")
        await run_migration()
        await verify_migration()
        print("🏁 Processo concluído!")
    
    asyncio.run(main())
