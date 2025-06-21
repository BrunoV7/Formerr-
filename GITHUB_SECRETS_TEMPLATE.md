# 🔐 Template de GitHub Secrets - Formerr CI/CD

## 📋 Configuração de Secrets

Este documento lista todos os secrets necessários para configurar a arquitetura de CI/CD do Formerr no GitHub.

## 🔑 Secrets Obrigatórios

### 🌍 Produção

| Secret | Descrição | Exemplo | Obrigatório |
|--------|-----------|---------|-------------|
| `DO_TOKEN_PROD` | Token da DigitalOcean para produção | `dop_v1_1234567890abcdef...` | ✅ |
| `DB_PASSWORD` | Senha do banco de dados de produção | `formerr_prod_pass_2024` | ✅ |
| `JWT_SECRET` | Chave secreta para JWT | `brunov7_super_secret_formerr_2025` | ✅ |
| `SESSION_SECRET` | Chave secreta para sessões | `brunov7_session_secret_2025` | ✅ |
| `CLIENT_ID` | ID do cliente GitHub OAuth | `Ov23libwTy1CTdfzvbRg` | ✅ |
| `CLIENT_SECRET` | Secret do cliente GitHub OAuth | `4f07c7baa3fba7eb00d2e57ba48ae2e15d2da110` | ✅ |

### 🧪 Staging

| Secret | Descrição | Exemplo | Obrigatório |
|--------|-----------|---------|-------------|
| `DO_TOKEN_STAGING` | Token da DigitalOcean para staging | `dop_v1_0987654321fedcba...` | ✅ |

## 🔑 Secrets Opcionais

### 🌍 Produção (Opcionais)

| Secret | Descrição | Exemplo | Padrão |
|--------|-----------|---------|--------|
| `DB_HOST` | Host do banco de dados | `postgres-service` | `postgres-service` |
| `DB_PORT` | Porta do banco de dados | `5432` | `5432` |
| `DB_USER` | Usuário do banco de dados | `formerr_user` | `formerr_user` |
| `DB_NAME` | Nome do banco de dados | `formerr_db` | `formerr_db` |
| `DATABASE_URL` | URL completa do banco | `postgresql+asyncpg://user:pass@host:port/db` | Construída automaticamente |

### 🧪 Staging (Opcionais)

| Secret | Descrição | Exemplo | Padrão |
|--------|-----------|---------|--------|
| `DB_PASSWORD_STAGING` | Senha do banco staging | `formerr_staging_pass_2024` | `formerr_staging_pass_2024` |
| `JWT_SECRET_STAGING` | Chave JWT staging | `brunov7_staging_secret_2025` | `brunov7_staging_secret_2025` |
| `SESSION_SECRET_STAGING` | Chave sessão staging | `brunov7_staging_session_2025` | `brunov7_staging_session_2025` |
| `DB_HOST_STAGING` | Host do banco staging | `postgres-service` | `postgres-service` |
| `DB_PORT_STAGING` | Porta do banco staging | `5432` | `5432` |
| `DB_USER_STAGING` | Usuário do banco staging | `formerr_user` | `formerr_user` |
| `DB_NAME_STAGING` | Nome do banco staging | `formerr_staging_db` | `formerr_staging_db` |
| `DATABASE_URL_STAGING` | URL completa do banco staging | `postgresql+asyncpg://user:pass@host:port/db` | Construída automaticamente |
| `CLIENT_ID_STAGING` | ID do cliente GitHub OAuth staging | `Ov23libwTy1CTdfzvbRg` | `Ov23libwTy1CTdfzvbRg` |
| `CLIENT_SECRET_STAGING` | Secret do cliente GitHub OAuth staging | `4f07c7baa3fba7eb00d2e57ba48ae2e15d2da110` | `4f07c7baa3fba7eb00d2e57ba48ae2e15d2da110` |

## 🛠️ Como Configurar

### 1. Acessar GitHub Secrets

1. Vá para o repositório no GitHub
2. Clique em **Settings**
3. No menu lateral, clique em **Secrets and variables** → **Actions**
4. Clique em **New repository secret**

### 2. Configurar Secrets Obrigatórios

#### DigitalOcean Tokens

1. **DO_TOKEN_PROD**
   ```bash
   # Gerar token na DigitalOcean
   # Dashboard → API → Generate New Token
   # Permissões: Read, Write
   ```

2. **DO_TOKEN_STAGING**
   ```bash
   # Gerar token na DigitalOcean (conta separada)
   # Dashboard → API → Generate New Token
   # Permissões: Read, Write
   ```

#### GitHub OAuth

1. **CLIENT_ID** e **CLIENT_SECRET**
   ```bash
   # GitHub → Settings → Developer settings → OAuth Apps
   # Criar novo OAuth App
   # Homepage URL: https://formerr.com
   # Authorization callback URL: https://formerr.com/auth/github/callback
   ```

#### Banco de Dados

1. **DB_PASSWORD**
   ```bash
   # Gerar senha forte
   openssl rand -base64 32
   ```

#### JWT e Sessão

1. **JWT_SECRET**
   ```bash
   # Gerar chave secreta
   openssl rand -base64 64
   ```

2. **SESSION_SECRET**
   ```bash
   # Gerar chave secreta
   openssl rand -base64 64
   ```

### 3. Configurar Secrets Opcionais (se necessário)

Se você quiser usar configurações específicas para staging, configure os secrets opcionais correspondentes.

## 🔒 Segurança

### Boas Práticas

- ✅ Use senhas fortes e únicas
- ✅ Rotacione tokens regularmente
- ✅ Use diferentes tokens para produção e staging
- ✅ Nunca commite secrets no código
- ✅ Use variáveis de ambiente em desenvolvimento

### Geração de Secrets

```bash
# Gerar senha forte
openssl rand -base64 32

# Gerar chave JWT
openssl rand -base64 64

# Gerar chave de sessão
openssl rand -base64 64
```

## 📋 Checklist de Configuração

### Secrets Obrigatórios
- [ ] `DO_TOKEN_PROD` configurado
- [ ] `DO_TOKEN_STAGING` configurado
- [ ] `DB_PASSWORD` configurado
- [ ] `JWT_SECRET` configurado
- [ ] `SESSION_SECRET` configurado
- [ ] `CLIENT_ID` configurado
- [ ] `CLIENT_SECRET` configurado

### Secrets Opcionais (se necessário)
- [ ] `DB_PASSWORD_STAGING` configurado
- [ ] `JWT_SECRET_STAGING` configurado
- [ ] `SESSION_SECRET_STAGING` configurado
- [ ] Outros secrets específicos configurados

### Validação
- [ ] Testar pipeline de infraestrutura
- [ ] Testar pipeline de aplicação
- [ ] Verificar logs de erro
- [ ] Validar deploy bem-sucedido

## 🚨 Troubleshooting

### Erro: "Invalid token"
- Verificar se o token da DigitalOcean está correto
- Verificar se o token tem permissões adequadas
- Verificar se a conta tem créditos suficientes

### Erro: "Database connection failed"
- Verificar se `DB_PASSWORD` está configurado
- Verificar se `DATABASE_URL` está correto (se usado)
- Verificar se o banco de dados está acessível

### Erro: "OAuth authentication failed"
- Verificar se `CLIENT_ID` e `CLIENT_SECRET` estão corretos
- Verificar se as URLs de callback estão configuradas
- Verificar se o OAuth App está ativo

## 📞 Suporte

Se você encontrar problemas com a configuração:

1. Verifique os logs das pipelines no GitHub Actions
2. Consulte a documentação da arquitetura
3. Verifique se todos os secrets estão configurados corretamente
4. Teste cada pipeline individualmente

---

**⚠️ Importante:** Nunca compartilhe ou commite estes secrets. Eles devem ser mantidos seguros e confidenciais. 