#!/usr/bin/env python3
"""
Script para gerar dados de teste completos para a API Formerr
- Cria um formulário
- Adiciona 3 seções com 10 perguntas cada
- Publica o formulário
- Gera 18 respostas com dados aleatórios
"""

import requests
import json
import random
import time
from faker import Faker

# Configurações
API_BASE_URL = "http://localhost:8000"
JWT_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJnaXRodWJfaWQiOjEwNDk0NTg3NywidXNlcm5hbWUiOiJCcnVub1Y3IiwibmFtZSI6IkJydW5vIFZpZWlyYSBOb2JyZSIsImVtYWlsIjoiYmFja3Vwbm9icmU2MkBnbWFpbC5jb20iLCJhdmF0YXJfdXJsIjoiaHR0cHM6Ly9hdmF0YXJzLmdpdGh1YnVzZXJjb250ZW50LmNvbS91LzEwNDk0NTg3Nz92PTQiLCJnaXRodWJfdXJsIjoiaHR0cHM6Ly9naXRodWIuY29tL0JydW5vVjciLCJyb2xlIjoiZnJlZSIsInBlcm1pc3Npb25zIjpbImNyZWF0ZV9mb3JtIl0sImxpbWl0cyI6eyJtYXhfZm9ybXMiOjMsIm1heF9zdWJtaXNzaW9uc19wZXJfbW9udGgiOjEwMCwibWF4X3F1ZXN0aW9uc19wZXJfZm9ybSI6MTAsIm1heF9maWxlX3NpemVfbWIiOjV9LCJjcmVhdGVkX2F0IjoiMjAyNS0wNi0yMFQyMTo0NjoxNS41ODQ0NDciLCJ1c2VyX3R5cGUiOiJnaXRodWJfdXNlciIsInNwcmludF92ZXJzaW9uIjoiZm9ybWVycl9wbGF0Zm9ybV8yMDI1IiwiaXNfYWRtaW4iOmZhbHNlLCJleHAiOjE3NTMwNDc5NzUsImlhdCI6MTc1MDQ1NTk3NSwiaXNzIjoiRm9ybWVyciBBUEktRm9ybWVyciBUZWFtIn0.dmieI7kyTJOHa7xk-ggqytjJIJ9etCWzuWaXf64Ocfc"

# Inicializar Faker para dados aleatórios
fake = Faker('pt_BR')

# Headers para requisições autenticadas
auth_headers = {
    "Authorization": f"Bearer {JWT_TOKEN}",
    "Content-Type": "application/json"
}

# Headers para requisições públicas
public_headers = {
    "Content-Type": "application/json"
}

def create_form():
    """Cria um novo formulário"""
    print("🔨 Criando novo formulário...")
    
    form_data = {
        "title": "Pesquisa de Satisfação do Cliente",
        "description": "Uma pesquisa completa para avaliar a experiência do cliente com nossos produtos e serviços",
        "icon": "📊",
        "folder_color": "#10B981"
    }
    
    response = requests.post(
        f"{API_BASE_URL}/forms",
        headers=auth_headers,
        json=form_data
    )
    
    if response.status_code == 200:
        form_id = response.json()["formId"]
        print(f"✅ Formulário criado com ID: {form_id}")
        return form_id
    else:
        print(f"❌ Erro ao criar formulário: {response.text}")
        return None

def create_sections(form_id):
    """Cria 3 seções com 10 perguntas cada"""
    print("📝 Criando seções e perguntas...")
    
    sections_data = [
        {
            "title": "Informações Pessoais",
            "description": "Dados básicos sobre o respondente",
            "questions": [
                {"title": "Qual é o seu nome completo?", "type": "text", "required": True, "placeholder": "Digite seu nome completo"},
                {"title": "Qual é o seu email?", "type": "email", "required": True, "placeholder": "seuemail@exemplo.com"},
                {"title": "Qual é a sua idade?", "type": "number", "required": True, "placeholder": "Ex: 25"},
                {"title": "Qual é o seu telefone?", "type": "text", "required": False, "placeholder": "(11) 99999-9999"},
                {"title": "Em qual cidade você mora?", "type": "text", "required": True, "placeholder": "Digite sua cidade"},
                {"title": "Qual é o seu estado civil?", "type": "select", "required": False, "options": {"choices": ["Solteiro(a)", "Casado(a)", "Divorciado(a)", "Viúvo(a)"]}},
                {"title": "Qual é o seu nível de escolaridade?", "type": "select", "required": False, "options": {"choices": ["Ensino Fundamental", "Ensino Médio", "Ensino Superior", "Pós-graduação"]}},
                {"title": "Qual é a sua profissão?", "type": "text", "required": False, "placeholder": "Digite sua profissão"},
                {"title": "Qual é a sua renda mensal?", "type": "select", "required": False, "options": {"choices": ["Até R$ 2.000", "R$ 2.001 - R$ 5.000", "R$ 5.001 - R$ 10.000", "Acima de R$ 10.000"]}},
                {"title": "Como você nos conheceu?", "type": "select", "required": True, "options": {"choices": ["Redes sociais", "Indicação de amigos", "Pesquisa no Google", "Publicidade", "Outros"]}}
            ]
        },
        {
            "title": "Avaliação do Produto/Serviço",
            "description": "Sua experiência com nossos produtos e serviços",
            "questions": [
                {"title": "Como você avalia nosso produto/serviço em geral?", "type": "select", "required": True, "options": {"choices": ["Excelente", "Muito bom", "Bom", "Regular", "Ruim"]}},
                {"title": "O produto/serviço atendeu suas expectativas?", "type": "select", "required": True, "options": {"choices": ["Superou", "Atendeu", "Não atendeu"]}},
                {"title": "Qual nota você daria para a qualidade? (1-10)", "type": "number", "required": True, "placeholder": "1 a 10"},
                {"title": "Qual nota você daria para o atendimento? (1-10)", "type": "number", "required": True, "placeholder": "1 a 10"},
                {"title": "Você recomendaria nosso produto/serviço?", "type": "select", "required": True, "options": {"choices": ["Certamente sim", "Provavelmente sim", "Talvez", "Provavelmente não", "Certamente não"]}},
                {"title": "O que mais gostou no produto/serviço?", "type": "textarea", "required": False, "placeholder": "Descreva os pontos positivos"},
                {"title": "O que poderia ser melhorado?", "type": "textarea", "required": False, "placeholder": "Sugestões de melhoria"},
                {"title": "Teve algum problema com o produto/serviço?", "type": "select", "required": False, "options": {"choices": ["Sim", "Não"]}},
                {"title": "Se sim, como foi resolvido?", "type": "textarea", "required": False, "placeholder": "Descreva como foi a resolução"},
                {"title": "Usaria nosso produto/serviço novamente?", "type": "select", "required": True, "options": {"choices": ["Certamente sim", "Provavelmente sim", "Talvez", "Provavelmente não", "Certamente não"]}}
            ]
        },
        {
            "title": "Feedback e Sugestões",
            "description": "Suas opiniões e sugestões para melhorarmos",
            "questions": [
                {"title": "Como você avalia nosso site/aplicativo?", "type": "select", "required": False, "options": {"choices": ["Excelente", "Muito bom", "Bom", "Regular", "Ruim"]}},
                {"title": "A navegação é intuitiva?", "type": "select", "required": False, "options": {"choices": ["Muito fácil", "Fácil", "Médio", "Difícil", "Muito difícil"]}},
                {"title": "O processo de compra foi fácil?", "type": "select", "required": False, "options": {"choices": ["Muito fácil", "Fácil", "Médio", "Difícil", "Muito difícil"]}},
                {"title": "Que funcionalidades gostaria de ver?", "type": "textarea", "required": False, "placeholder": "Sugestões de novas funcionalidades"},
                {"title": "Como avalia nosso suporte ao cliente?", "type": "select", "required": False, "options": {"choices": ["Excelente", "Muito bom", "Bom", "Regular", "Ruim", "Não utilizei"]}},
                {"title": "Nossos preços são justos?", "type": "select", "required": False, "options": {"choices": ["Muito baratos", "Baratos", "Justos", "Caros", "Muito caros"]}},
                {"title": "Que canais de comunicação prefere?", "type": "select", "required": False, "options": {"choices": ["WhatsApp", "Email", "Telefone", "Chat online", "Redes sociais"]}},
                {"title": "Gostaria de receber novidades por email?", "type": "select", "required": False, "options": {"choices": ["Sim", "Não"]}},
                {"title": "Comentários adicionais", "type": "textarea", "required": False, "placeholder": "Deixe seus comentários, críticas ou sugestões"},
                {"title": "Nota geral para nossa empresa (1-10)", "type": "number", "required": True, "placeholder": "1 a 10"}
            ]
        }
    ]
    
    section_ids = []
    question_ids = []
    
    for i, section_data in enumerate(sections_data, 1):
        print(f"📋 Criando seção {i}: {section_data['title']}")
        
        response = requests.post(
            f"{API_BASE_URL}/forms/{form_id}/sections",
            headers=auth_headers,
            json=section_data
        )
        
        if response.status_code == 200:
            section_id = response.json()["sectionId"]
            section_ids.append(section_id)
            print(f"✅ Seção criada com ID: {section_id}")
            
            # Simular um pequeno delay
            time.sleep(0.5)
        else:
            print(f"❌ Erro ao criar seção {i}: {response.text}")
    
    # Buscar IDs das perguntas do formulário público
    print("🔍 Buscando IDs das perguntas...")
    
    # Primeiro publicar o formulário
    publish_data = {"status": "public"}
    pub_response = requests.put(
        f"{API_BASE_URL}/forms/{form_id}/publish",
        headers=auth_headers,
        json=publish_data
    )
    
    if pub_response.status_code != 200:
        print(f"❌ Erro ao publicar formulário temporariamente: {pub_response.text}")
        return section_ids, question_ids
    
    # Agora buscar as perguntas
    response = requests.get(f"{API_BASE_URL}/forms/{form_id}/public", headers=public_headers)
    
    if response.status_code == 200:
        form_data = response.json()
        for section in form_data["sections"]:
            for question in section["questions"]:
                question_ids.append({
                    "id": question["id"],
                    "title": question["title"],
                    "type": question["type"],
                    "options": question.get("options")
                })
        print(f"✅ Encontradas {len(question_ids)} perguntas")
    
    return section_ids, question_ids

def publish_form(form_id):
    """Publica o formulário"""
    print("🚀 Publicando formulário...")
    
    publish_data = {
        "status": "public"
    }
    
    response = requests.put(
        f"{API_BASE_URL}/forms/{form_id}/publish",
        headers=auth_headers,
        json=publish_data
    )
    
    if response.status_code == 200:
        print("✅ Formulário publicado com sucesso")
        return True
    else:
        print(f"❌ Erro ao publicar formulário: {response.text}")
        return False

def generate_random_answer(question):
    """Gera uma resposta aleatória baseada no tipo da pergunta"""
    question_type = question["type"]
    question_title = question["title"].lower()
    
    if question_type == "text":
        if "nome" in question_title:
            return [fake.name()]
        elif "telefone" in question_title:
            return [fake.phone_number()]
        elif "cidade" in question_title:
            return [fake.city()]
        elif "profissão" in question_title:
            profissoes = ["Desenvolvedor", "Designer", "Gerente", "Analista", "Consultor", "Professor", "Médico", "Advogado", "Engenheiro", "Vendedor"]
            return [random.choice(profissoes)]
        else:
            return [fake.sentence()]
    
    elif question_type == "email":
        return [fake.email()]
    
    elif question_type == "number":
        if "idade" in question_title:
            return [str(random.randint(18, 65))]
        elif "nota" in question_title:
            return [str(random.randint(1, 10))]
        else:
            return [str(random.randint(1, 100))]
    
    elif question_type == "select":
        # Para perguntas de múltipla escolha, escolher uma opção aleatória
        if question.get("options") and question["options"].get("choices"):
            return [random.choice(question["options"]["choices"])]
        else:
            return ["Sim"]
    
    elif question_type == "textarea":
        return [fake.paragraph()]
    
    else:
        return [fake.word()]

def generate_responses(form_id, question_ids, num_responses=18):
    """Gera respostas aleatórias para o formulário"""
    print(f"🎲 Gerando {num_responses} respostas aleatórias...")
    
    for i in range(num_responses):
        print(f"📝 Gerando resposta {i+1}/{num_responses}")
        
        # Gerar dados do respondente
        respondent_email = fake.email()
        
        # Gerar respostas para todas as perguntas
        answers = []
        for question in question_ids:
            # Algumas perguntas podem não ser respondidas (simulando comportamento real)
            if random.random() > 0.1:  # 90% de chance de responder cada pergunta
                answer = generate_random_answer(question)
                answers.append({
                    "question_id": question["id"],
                    "value": answer
                })
        
        # Submeter resposta
        submission_data = {
            "answers": answers,
            "respondent_email": respondent_email
        }
        
        response = requests.post(
            f"{API_BASE_URL}/forms/{form_id}/submit",
            headers=public_headers,
            json=submission_data
        )
        
        if response.status_code == 200:
            session_id = response.json()["session_id"]
            print(f"✅ Resposta {i+1} enviada - Session ID: {session_id}")
        else:
            print(f"❌ Erro ao enviar resposta {i+1}: {response.text}")
        
        # Pequeno delay entre submissões
        time.sleep(0.2)

def main():
    """Função principal"""
    print("🚀 Iniciando geração de dados de teste completos...")
    print("=" * 60)
    
    # 1. Criar formulário
    form_id = create_form()
    if not form_id:
        return
    
    # 2. Criar seções e perguntas
    section_ids, question_ids = create_sections(form_id)
    if not question_ids:
        print("❌ Não foi possível obter as perguntas")
        return
    
    # 3. Publicar formulário
    if not publish_form(form_id):
        return
    
    # 4. Gerar respostas
    generate_responses(form_id, question_ids, 18)
    
    print("=" * 60)
    print("🎉 Geração de dados de teste concluída!")
    print(f"📊 Formulário ID: {form_id}")
    print(f"📋 {len(section_ids)} seções criadas")
    print(f"❓ {len(question_ids)} perguntas criadas")
    print(f"📝 18 respostas geradas")
    print(f"🌐 Acesse: {API_BASE_URL}/forms/{form_id}/public")

if __name__ == "__main__":
    main()
