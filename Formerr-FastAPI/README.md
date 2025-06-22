# Formerr API - Sistema de Formulários

Sistema profissional de criação e gerenciamento de formulários desenvolvido com FastAPI.

## 📋 Sobre o Projeto

A Formerr API é uma solução completa para criação, gerenciamento e análise de formulários online. Oferece funcionalidades avançadas como autenticação OAuth, webhooks, sistema de emails e analytics detalhados.

**Desenvolvido por:** Equipe de Desenvolvimento  
**Tecnologia:** FastAPI + PostgreSQL  
**Versão:** 1.0.0

## 🚀 Funcionalidades Principais

- ✅ **Criação de Formulários** - Interface intuitiva para criação de formulários customizados
- ✅ **Autenticação OAuth** - Login social via GitHub
- ✅ **Sistema de Permissões** - Controle granular de acesso
- ✅ **Submissões em Tempo Real** - Coleta e processamento de dados
- ✅ **Webhooks** - Integração com sistemas externos
- ✅ **Sistema de Email** - Notificações automáticas
- ✅ **Analytics** - Relatórios e métricas detalhadas
- ✅ **APIs Públicas** - Endpoints para integração

## 🏗️ Arquitetura do Projeto

```
app/
├── auth/           # Sistema de autenticação
├── forms/          # Gerenciamento de formulários
├── submissions/    # Processamento de submissões
├── webhooks/       # Integração com webhooks
├── email/          # Sistema de email
├── analytics/      # Métricas e relatórios
├── public/         # APIs públicas
├── database/       # Modelos e conexão DB
├── core/           # Middleware e utilidades
└── monitoring/     # Métricas (em desenvolvimento)
```

## 🛠️ Configuração do Ambiente

### Pré-requisitos

- Python 3.11+
- PostgreSQL 12+
- Git

### Instalação

1. **Clone o repositório**
```bash
git clone <url-do-repositorio>
cd Formerr-FastAPI
```

2. **Configure o ambiente virtual**
```bash
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# ou
.venv\\Scripts\\activate  # Windows
```

3. **Instale as dependências**
```bash
pip install -r requirements.txt
```

4. **Configure as variáveis de ambiente**

Crie um arquivo `.env` na raiz do projeto:

```env
# Configurações gerais
ENVIRONMENT=development

# GitHub OAuth
GITHUB_CLIENT_ID=seu_GITHUB_CLIENT_ID
GITHUB_CLIENT_SECRET=seu_github_client_secret

# Segurança
JWT_SECRET=sua_chave_jwt_super_secreta
SESSION_SECRET=sua_chave_sessao_super_secreta

# Banco de dados
DATABASE_URL=postgresql://usuario:senha@host:porta/banco
DB_HOST=localhost
DB_PORT=5432
DB_USER=seu_usuario
DB_PASSWORD=sua_senha
DB_NAME=formerr_db

# URLs de redirecionamento
FRONTEND_SUCCESS_URL=http://localhost:3000/auth/success
FRONTEND_ERROR_URL=http://localhost:3000/auth/error
OAUTH_CALLBACK_URL=http://localhost:8000/auth/github/callback
```

5. **Execute as migrações do banco**
```bash
alembic upgrade head
```

6. **Inicie a aplicação**
```bash
python main.py
```

A API estará disponível em: http://localhost:8000

## 📚 Documentação

- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **Health Check:** http://localhost:8000/health

## 🔐 Autenticação

A aplicação usa **JWT (JSON Web Tokens)** para autenticação. 

### Como obter um token:

1. Acesse `GET /auth/github`
2. Complete o fluxo OAuth
3. Receba o JWT no redirecionamento
4. Use o token no header: `Authorization: Bearer <seu_token>`

### Exemplo de uso:
```bash
curl -H "Authorization: Bearer <seu_token>" \
     http://localhost:8000/api/forms
```

## 📁 Principais Endpoints

### Autenticação
- `GET /auth/github` - Inicia OAuth com GitHub
- `GET /auth/github/callback` - Callback do OAuth
- `GET /auth/me` - Dados do usuário atual

### Formulários
- `GET /api/forms` - Lista formulários
- `POST /api/forms` - Cria novo formulário
- `GET /api/forms/{id}` - Detalhes do formulário
- `PUT /api/forms/{id}` - Atualiza formulário
- `DELETE /api/forms/{id}` - Remove formulário

### Submissões
- `GET /api/submissions` - Lista submissões
- `POST /api/public/forms/{id}/submit` - Submete formulário (público)

### Analytics
- `GET /api/analytics/dashboard` - Dashboard principal
- `GET /api/analytics/forms/{id}` - Analytics do formulário

## 🧪 Testando a API

### Teste básico de funcionamento:
```bash
curl http://localhost:8000/
```

### Teste do health check:
```bash
curl http://localhost:8000/health
```

### Teste com autenticação:
```bash
# 1. Obtenha um token via OAuth
# 2. Use o token:
curl -H "Authorization: Bearer <token>" \
     http://localhost:8000/api/forms
```

## 🔧 Desenvolvimento

### Estrutura de arquivos importantes:

- **`main.py`** - Aplicação principal
- **`app/config.py`** - Configurações centralizadas
- **`app/dependencies.py`** - Dependencies do FastAPI
- **`requirements.txt`** - Dependências Python

### Para desenvolvedores iniciantes:

1. **Entenda o FastAPI:** Leia a [documentação oficial](https://fastapi.tiangolo.com/)
2. **Estude as dependencies:** Veja `app/dependencies.py`
3. **Analise um módulo:** Comece com `app/public/` (mais simples)
4. **Teste localmente:** Use a documentação automática em `/docs`

### Convenções do código:

- **Docstrings em português** - Para facilitar entendimento da equipe
- **Comentários explicativos** - Especialmente em lógicas complexas
- **Nomes descritivos** - Variáveis e funções auto-explicativas
- **Separação por responsabilidade** - Cada módulo tem uma função específica

## 🐛 Troubleshooting

### Problemas comuns:

**Erro de autenticação:**
- Verifique se o `GITHUB_CLIENT_ID` e `GITHUB_CLIENT_SECRET` estão corretos
- Confirme se a URL de callback está registrada no GitHub

**Erro de banco de dados:**
- Verifique se o PostgreSQL está rodando
- Confirme as credenciais no `.env`
- Execute `alembic upgrade head`

**Erro de dependências:**
- Reinstale: `pip install -r requirements.txt`
- Ative o ambiente virtual

## 🤝 Contribuindo

1. Crie uma branch para sua feature
2. Adicione comentários em português
3. Teste localmente
4. Abra um Pull Request

## 📞 Suporte

Para dúvidas técnicas:
- Consulte a documentação em `/docs`
- Verifique os logs da aplicação
- Entre em contato com a equipe de desenvolvimento

---

**Formerr API** - Desenvolvido com ❤️ pela Equipe de Desenvolvimento
