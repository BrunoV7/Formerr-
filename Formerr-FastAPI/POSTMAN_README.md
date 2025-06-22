# 🚀 Coleção Postman Formerr API - Enhanced

Esta é uma coleção completa e otimizada para testar a API Formerr com todas as funcionalidades avançadas do Postman.

## 📁 Arquivos Incluídos

- `Formerr-API-Enhanced.postman_collection.json` - Coleção principal com todos os endpoints
- `Formerr-API-Development.postman_environment.json` - Ambiente de desenvolvimento
- `Formerr-API-Production.postman_environment.json` - Ambiente de produção

## 🔧 Como Configurar

### 1. Importar no Postman

1. Abra o Postman
2. Clique em **Import**
3. Importe os 3 arquivos JSON
4. Selecione o ambiente desejado (Development ou Production)

### 2. Configurar Variáveis de Ambiente

**Para Development:**
- `base_url`: `http://localhost:8000` (já configurado)
- `GITHUB_CLIENT_ID`: Seu Client ID do GitHub OAuth
- `github_client_secret`: Seu Client Secret do GitHub OAuth

**Para Production:**
- `base_url`: URL do seu servidor de produção
- `GITHUB_CLIENT_ID`: Client ID de produção
- `github_client_secret`: Client Secret de produção

### 3. Configurar GitHub OAuth

1. Acesse [GitHub Developer Settings](https://github.com/settings/developers)
2. Crie uma nova OAuth App
3. Configure:
   - **Application name**: Formerr API
   - **Homepage URL**: `http://localhost:8000` (dev) ou sua URL de produção
   - **Authorization callback URL**: `http://localhost:8000/auth/github/callback`

## 🏗️ Estrutura da Coleção

### 🏥 Health & Status
- **Health Check** - Verifica se a API está funcionando
- **Status Check** - Status detalhado da aplicação

### 🔐 Authentication
- **GitHub OAuth - Initiate** - Inicia fluxo OAuth
- **GitHub OAuth - Callback** - Callback do GitHub
- **Get Current User** - Dados do usuário logado
- **Logout** - Encerra sessão
- **Auth Test** - Testa autenticação

### 📊 Dashboard
- **Dashboard Stats** - Estatísticas resumidas
- **User Forms List** - Lista formulários do usuário
- **Dashboard Analytics** - Dados para gráficos
- **Recent Activity** - Atividades recentes

### 📝 Forms Management
- **Create Form (Draft)** - Criar formulário
- **Add Section with Questions** - Adicionar seções
- **Update Section** - Atualizar seções
- **Delete Section** - Remover seções
- **Publish Form** - Publicar formulário
- **Get Public Form** - Visualizar formulário público
- **Submit Form Response** - Enviar resposta

### 📈 Analytics & Reports
- **Form Analytics** - Analytics do formulário
- **Form Responses List** - Lista de respostas
- **Response Session Detail** - Detalhes da resposta

### 🧪 Test Scenarios
- **Complete Flow Test** - Teste do fluxo completo automatizado

## ✨ Funcionalidades Avançadas

### 🔄 Variáveis Automáticas
- **Token JWT**: Salvo automaticamente após autenticação
- **IDs de recursos**: Form ID, Section ID, Question ID salvos automaticamente
- **Dados aleatórios**: `{{$randomEmail}}`, `{{$randomFullName}}`, `{{$timestamp}}`

### 🧪 Testes Automatizados
- Validação de status codes
- Verificação de estrutura de resposta
- Medição de performance
- Testes de integridade dos dados

### 📝 Scripts Automáticos
- **Pre-request**: Configuração automática de variáveis
- **Post-response**: Extração automática de IDs e tokens
- **Global scripts**: Logging e tratamento de erros

### 🎯 Organização
- **Pastas temáticas**: Endpoints organizados por funcionalidade
- **Descrições detalhadas**: Cada endpoint com documentação
- **Fluxo lógico**: Ordem dos endpoints segue fluxo de uso

## 🚀 Como Usar

### Fluxo Básico

1. **Execute Health Check** para verificar se a API está funcionando
2. **Configure OAuth** no GitHub e nas variáveis de ambiente
3. **Execute autenticação** (será redirecionado para GitHub)
4. **Use os demais endpoints** (token será inserido automaticamente)

### Fluxo Completo de Teste

1. **Create Form (Draft)** - Cria formulário
2. **Add Section with Questions** - Adiciona perguntas
3. **Publish Form** - Publica formulário
4. **Submit Form Response** - Envia resposta de teste
5. **Form Analytics** - Verifica estatísticas

### Teste Automatizado

Execute a pasta **🧪 Test Scenarios > Complete Flow Test** para rodar o fluxo completo automaticamente.

## 🔧 Personalização

### Adicionar Novos Endpoints

1. Crie nova request na pasta apropriada
2. Configure headers com `{{token}}` para endpoints protegidos
3. Adicione testes na aba **Tests**
4. Use variáveis `{{baseUrl}}` e outras conforme necessário

### Modificar Ambientes

Edite os arquivos `.postman_environment.json` ou crie novos ambientes:
- Staging
- QA
- Local Docker
- etc.

## 🐛 Troubleshooting

### Token não está sendo salvo
- Verifique se a resposta da autenticação contém `access_token`
- Execute **Auth Test** para validar token

### Endpoint retorna 401
- Execute **Get Current User** para verificar se está autenticado
- Re-execute a autenticação se necessário

### Variáveis não estão sendo substituídas
- Certifique-se de que o ambiente correto está selecionado
- Verifique se as variáveis estão definidas no ambiente

### OAuth não funciona
- Verifique configuração no GitHub
- Confirme URLs de callback
- Valide Client ID e Secret

## 📚 Recursos Adicionais

- [Documentação FastAPI](https://fastapi.tiangolo.com/)
- [GitHub OAuth Documentation](https://docs.github.com/en/developers/apps/building-oauth-apps)
- [Postman Learning Center](https://learning.postman.com/)

---

**Desenvolvido com ❤️ pela Equipe Formerr**
