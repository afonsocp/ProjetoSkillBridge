"""
Módulo de Geração de Plano de Estudos Personalizado com IA Generativa
Integração: Gemini API para geração de conteúdo estruturado
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict
from google import genai
from google.genai import types
import os
from dotenv import load_dotenv
from pathlib import Path
import json


class QuotaExceededException(Exception):
    """Exceção customizada para quota excedida"""
    pass

# Carregar variáveis de ambiente
env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=env_path)

# Obter API key e inicializar cliente Gemini
gemini_api_key = os.getenv("GEMINI_API_KEY")
if gemini_api_key:
    # Mostrar apenas os primeiros e últimos caracteres da chave para segurança
    key_preview = f"{gemini_api_key[:10]}...{gemini_api_key[-4:]}" if len(gemini_api_key) > 14 else "***"
    print(f"🔑 GEMINI_API_KEY carregada: {key_preview}")
    client = genai.Client(api_key=gemini_api_key)
else:
    print("⚠️ GEMINI_API_KEY não encontrada no arquivo .env!")
    client = None

app = FastAPI(
    title="IOT - Geração de Plano de Estudos com IA",
    description="IA Generativa para criar planos de estudos personalizados",
    version="1.0.0",
)


class PlanoEstudosRequest(BaseModel):
    objetivo_carreira: str
    nivel_atual: str  # Iniciante, Intermediário, Avançado
    competencias_atuais: List[str]
    tempo_disponivel_semana: int  # horas por semana
    prazo_meses: Optional[int] = 6
    areas_interesse: Optional[List[str]] = None


class EtapaEstudo(BaseModel):
    ordem: int
    titulo: str
    descricao: str
    duracao_semanas: int
    recursos_sugeridos: List[str]
    competencias_desenvolvidas: List[str]


class PlanoEstudosResponse(BaseModel):
    objetivo_carreira: str
    nivel_atual: str
    prazo_total_meses: int
    horas_totais_estimadas: int
    etapas: List[EtapaEstudo]
    recursos_adicionais: List[str]
    metricas_sucesso: List[str]
    motivacao: str


async def gerar_plano_estudos(request: PlanoEstudosRequest):
    """
    Gera um plano de estudos personalizado usando IA Generativa (Gemini).
    
    Demonstra:
    - Prompt Engineering avançado
    - Geração de conteúdo estruturado
    - Personalização baseada em perfil do usuário
    """
    # Verificar se API key está configurada
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or client is None:
        print("⚠️ GEMINI_API_KEY não configurada ou cliente não inicializado. Usando plano fallback.")
        plano_fallback_dict = criar_plano_fallback(request, "")
        return processar_resposta_gemini_fallback(plano_fallback_dict, request)
    
    try:
        print("🤖 Tentando chamar Gemini API...")
        # Construir prompt estruturado
        prompt = construir_prompt_plano_estudos(request)
        
        # Chamar Gemini
        resposta_gemini = chamar_gemini_plano_estudos(prompt)
        print("✅ Gemini API respondeu com sucesso!")
        print(f"📝 Resposta recebida (primeiros 200 chars): {resposta_gemini[:200]}...")
        
        # Processar resposta
        plano_estruturado = processar_resposta_gemini(resposta_gemini, request)
        print("✅ Plano processado com sucesso usando resposta do Gemini!")
        
        return plano_estruturado
        
    except QuotaExceededException:
        # Retornar plano fallback quando quota excedida
        print("⚠️ Quota do Gemini excedida. Usando plano fallback.")
        plano_fallback_dict = criar_plano_fallback(request, "")
        return processar_resposta_gemini_fallback(plano_fallback_dict, request)
    except Exception as e:
        error_msg = str(e)
        print(f"❌ Erro ao chamar Gemini: {error_msg}")
        # Verificar se é erro de quota excedida (fallback adicional)
        if "429" in error_msg or "RESOURCE_EXHAUSTED" in error_msg or "quota" in error_msg.lower():
            print("⚠️ Quota do Gemini excedida (detectado no catch geral). Usando plano fallback.")
            plano_fallback_dict = criar_plano_fallback(request, "")
            return processar_resposta_gemini_fallback(plano_fallback_dict, request)
        else:
            print(f"⚠️ Erro desconhecido do Gemini. Usando plano fallback. Erro: {error_msg}")
            # Em caso de erro desconhecido, também usar fallback para não quebrar a aplicação
            plano_fallback_dict = criar_plano_fallback(request, "")
            return processar_resposta_gemini_fallback(plano_fallback_dict, request)


def construir_prompt_plano_estudos(request: PlanoEstudosRequest) -> str:
    """Constrói prompt estruturado para Gemini usando técnicas de Prompt Engineering"""
    
    prompt = f"""
Você é um especialista em educação e desenvolvimento de carreira. Crie um plano de estudos personalizado e detalhado.

PERFIL DO USUÁRIO:
- Objetivo de Carreira: {request.objetivo_carreira}
- Nível Atual: {request.nivel_atual}
- Competências Atuais: {', '.join(request.competencias_atuais)}
- Tempo Disponível: {request.tempo_disponivel_semana} horas por semana
- Prazo Desejado: {request.prazo_meses} meses
- Áreas de Interesse: {', '.join(request.areas_interesse) if request.areas_interesse else 'Não especificado'}

TAREFAS:
1. Crie um plano de estudos estruturado em ETAPAS progressivas
2. Cada etapa deve ter:
   - Título claro e objetivo
   - Descrição detalhada do que será aprendido
   - Duração em semanas (realista)
   - Recursos sugeridos (cursos, livros, projetos práticos)
   - Competências que serão desenvolvidas
3. Calcule o tempo total necessário
4. Sugira recursos adicionais (comunidades, certificações, etc.)
5. Defina métricas de sucesso para acompanhamento
6. Inclua uma mensagem motivacional personalizada

FORMATO DE RESPOSTA (JSON):
{{
  "objetivo_carreira": "{request.objetivo_carreira}",
  "nivel_atual": "{request.nivel_atual}",
  "prazo_total_meses": {request.prazo_meses},
  "horas_totais_estimadas": <número>,
  "etapas": [
    {{
      "ordem": 1,
      "titulo": "...",
      "descricao": "...",
      "duracao_semanas": <número>,
      "recursos_sugeridos": ["...", "..."],
      "competencias_desenvolvidas": ["...", "..."]
    }}
  ],
  "recursos_adicionais": ["...", "..."],
  "metricas_sucesso": ["...", "..."],
  "motivacao": "..."
}}

IMPORTANTE:
- Seja realista com os prazos
- Adapte o plano ao nível atual do usuário
- Inclua projetos práticos em cada etapa
- Foque em competências relevantes para o objetivo de carreira
- Responda APENAS com JSON válido, sem markdown, sem explicações adicionais
"""
    
    return prompt


def chamar_gemini_plano_estudos(prompt: str) -> str:
    """Chama Gemini API com configurações otimizadas para geração de conteúdo estruturado"""
    if client is None:
        raise Exception("Cliente Gemini não inicializado. Verifique GEMINI_API_KEY no arquivo .env")
    
    try:
        # Mostrar preview da chave sendo usada
        api_key = os.getenv("GEMINI_API_KEY", "")
        key_preview = f"{api_key[:10]}...{api_key[-4:]}" if len(api_key) > 14 else "***"
        print(f"📡 Chamando Gemini API (modelo: gemini-2.0-flash-exp) com chave: {key_preview}")
        response = client.models.generate_content(
            model='gemini-2.0-flash-exp',
            contents=prompt,
            config=types.GenerateContentConfig(
                temperature=0.7,  # Criatividade balanceada
                top_p=0.9,
                top_k=40,
            ),
        )
        
        resposta_texto = response.text
        print(f"✅ Gemini retornou resposta com {len(resposta_texto)} caracteres")
        return resposta_texto
        
    except Exception as e:
        error_str = str(e)
        print(f"❌ Erro na chamada ao Gemini: {error_str}")
        # Verificar se é erro de quota excedida
        if "429" in error_str or "RESOURCE_EXHAUSTED" in error_str or "quota" in error_str.lower():
            # Lançar exceção especial que será capturada no handler
            raise QuotaExceededException("Quota do Gemini excedida")
        else:
            raise Exception(f"Erro ao chamar Gemini: {error_str}")


def processar_resposta_gemini(resposta: str, request: PlanoEstudosRequest) -> PlanoEstudosResponse:
    """Processa resposta do Gemini e estrutura em modelo Pydantic"""
    try:
        # Limpar markdown se existir
        resposta_limpa = resposta.replace("```json", "").replace("```", "").strip()
        
        # Tentar parsear JSON
        try:
            dados = json.loads(resposta_limpa)
            print("✅ JSON do Gemini parseado com sucesso!")
        except json.JSONDecodeError as json_err:
            # Se não for JSON válido, criar estrutura básica
            print(f"⚠️ Resposta do Gemini não é JSON válido. Erro: {json_err}")
            print(f"📝 Tentando usar resposta como texto e criar estrutura básica...")
            dados = criar_plano_fallback(request, resposta)
        
        return processar_resposta_gemini_fallback(dados, request)
        
    except Exception as e:
        # Fallback em caso de erro
        print(f"❌ Erro ao processar resposta do Gemini: {str(e)}")
        dados_fallback = criar_plano_fallback(request, resposta)
        return processar_resposta_gemini_fallback(dados_fallback, request)


def processar_resposta_gemini_fallback(dados: dict, request: PlanoEstudosRequest) -> PlanoEstudosResponse:
    """Processa dados estruturados em PlanoEstudosResponse"""
    try:
        # Mapear etapas
        etapas = []
        etapas_data = dados.get("etapas", [])
        
        # Garantir que etapas_data é uma lista
        if not isinstance(etapas_data, list):
            etapas_data = []
        
        for etapa_data in etapas_data:
            if not isinstance(etapa_data, dict):
                continue
            try:
                etapa = EtapaEstudo(
                    ordem=etapa_data.get("ordem", len(etapas) + 1),
                    titulo=etapa_data.get("titulo", f"Etapa {len(etapas) + 1}"),
                    descricao=etapa_data.get("descricao", ""),
                    duracao_semanas=etapa_data.get("duracao_semanas", 2),
                    recursos_sugeridos=etapa_data.get("recursos_sugeridos", []) or [],
                    competencias_desenvolvidas=etapa_data.get("competencias_desenvolvidas", []) or []
                )
                etapas.append(etapa)
            except Exception as e:
                print(f"⚠️ Erro ao processar etapa: {str(e)}")
                continue
        
        # Se não houver etapas, criar uma básica
        if not etapas:
            etapas.append(EtapaEstudo(
                ordem=1,
                titulo="Fundamentos",
                descricao=f"Estabeleça uma base sólida em {request.objetivo_carreira}",
                duracao_semanas=4,
                recursos_sugeridos=["Cursos online", "Documentação oficial"],
                competencias_desenvolvidas=request.competencias_atuais[:2] if request.competencias_atuais else []
            ))
        
        # Criar resposta estruturada
        return PlanoEstudosResponse(
            objetivo_carreira=dados.get("objetivo_carreira", request.objetivo_carreira) or request.objetivo_carreira,
            nivel_atual=dados.get("nivel_atual", request.nivel_atual) or request.nivel_atual,
            prazo_total_meses=dados.get("prazo_total_meses", request.prazo_meses) or request.prazo_meses or 6,
            horas_totais_estimadas=dados.get("horas_totais_estimadas", request.tempo_disponivel_semana * (request.prazo_meses or 6) * 4),
            etapas=etapas,
            recursos_adicionais=dados.get("recursos_adicionais", []) or [],
            metricas_sucesso=dados.get("metricas_sucesso", []) or [],
            motivacao=dados.get("motivacao", f"Continue focado em {request.objetivo_carreira}!") or f"Continue focado em {request.objetivo_carreira}!"
        )
    except Exception as e:
        print(f"❌ Erro ao processar resposta fallback: {str(e)}")
        import traceback
        traceback.print_exc()
        # Retornar resposta mínima válida
        return PlanoEstudosResponse(
            objetivo_carreira=request.objetivo_carreira,
            nivel_atual=request.nivel_atual,
            prazo_total_meses=request.prazo_meses or 6,
            horas_totais_estimadas=request.tempo_disponivel_semana * (request.prazo_meses or 6) * 4,
            etapas=[EtapaEstudo(
                ordem=1,
                titulo="Plano de Estudos",
                descricao=f"Desenvolva suas habilidades em {request.objetivo_carreira}",
                duracao_semanas=4,
                recursos_sugeridos=["Cursos online", "Documentação"],
                competencias_desenvolvidas=request.competencias_atuais[:2] if request.competencias_atuais else []
            )],
            recursos_adicionais=["Comunidades online"],
            metricas_sucesso=["Conclusão de projetos"],
            motivacao="Continue estudando!"
        )


def criar_plano_fallback(request: PlanoEstudosRequest, resposta_texto: str) -> dict:
    """Cria plano básico caso Gemini não retorne JSON válido ou quota excedida"""
    # Criar etapas baseadas no objetivo e competências
    etapas = []
    prazo_meses = request.prazo_meses or 6  # Default 6 meses se None
    num_etapas = min(3, max(2, prazo_meses // 2)) if prazo_meses > 0 else 2
    
    # Determinar recursos específicos baseados no objetivo
    objetivo_lower = request.objetivo_carreira.lower()
    recursos_especificos = []
    if "microservices" in objetivo_lower or "microserviços" in objetivo_lower:
        recursos_especificos = [
            "Curso: Spring Cloud e Microservices (Udemy/Coursera)",
            "Documentação: Spring Cloud Gateway, Eureka, Config Server",
            "Projeto prático: Sistema de e-commerce com microservices",
            "Livro: 'Building Microservices' - Sam Newman"
        ]
    elif "java" in objetivo_lower:
        recursos_especificos = [
            "Curso: Java Completo (Nélio Alves - Udemy)",
            "Documentação oficial: Oracle Java Documentation",
            "Projeto prático: API REST com Spring Boot",
            "Livro: 'Effective Java' - Joshua Bloch"
        ]
    else:
        recursos_especificos = [
            "Cursos online especializados na área",
            "Documentação oficial das tecnologias",
            "Projetos práticos para portfólio",
            "Comunidades de desenvolvedores (Stack Overflow, Reddit)"
        ]
    
    for i in range(num_etapas):
        etapa_num = i + 1
        semanas_por_etapa = max(4, prazo_meses * 4 // num_etapas) if num_etapas > 0 else 4
        
        if etapa_num == 1:
            titulo = "Fundamentos e Base Sólida"
            competencias_base = request.competencias_atuais[:2] if len(request.competencias_atuais) >= 2 else request.competencias_atuais
            descricao = f"Estabeleça uma base sólida em {', '.join(competencias_base)}. Foque em entender os conceitos fundamentais e práticas essenciais."
            competencias = competencias_base
            recursos_etapa = recursos_especificos[:2] if recursos_especificos else ["Cursos online especializados", "Documentação oficial"]
        elif etapa_num == 2:
            titulo = "Aprofundamento e Prática"
            descricao = f"Aprofunde seus conhecimentos e aplique em projetos práticos relacionados a {request.objetivo_carreira}. Desenvolva projetos reais para consolidar o aprendizado."
            competencias = request.competencias_atuais[1:3] if len(request.competencias_atuais) >= 3 else request.competencias_atuais
            recursos_etapa = recursos_especificos[2:] if len(recursos_especificos) > 2 else ["Projetos práticos", "Comunidades de desenvolvedores"]
        else:
            titulo = "Especialização e Projetos Avançados"
            descricao = f"Desenvolva projetos avançados e especialize-se em {request.objetivo_carreira}. Crie soluções complexas e publique seu portfólio."
            competencias = request.competencias_atuais[-2:] if len(request.competencias_atuais) >= 2 else request.competencias_atuais
            recursos_etapa = recursos_especificos if recursos_especificos else ["Projetos avançados", "Certificações profissionais"]
        
        etapas.append({
            "ordem": etapa_num,
            "titulo": titulo,
            "descricao": descricao,
            "duracao_semanas": semanas_por_etapa,
            "recursos_sugeridos": recursos_etapa,
            "competencias_desenvolvidas": competencias
        })
    
    return {
        "objetivo_carreira": request.objetivo_carreira,
        "nivel_atual": request.nivel_atual,
        "prazo_total_meses": prazo_meses,
        "horas_totais_estimadas": request.tempo_disponivel_semana * prazo_meses * 4,
        "etapas": etapas,
        "recursos_adicionais": [
            "Comunidades online (Stack Overflow, Reddit)",
            "Fóruns de discussão",
            "Certificações profissionais",
            "Networking com profissionais da área"
        ],
        "metricas_sucesso": [
            "Conclusão de projetos práticos",
            "Aplicação do conhecimento em situações reais",
            "Participação ativa em comunidades",
            "Desenvolvimento de portfólio"
        ],
        "motivacao": resposta_texto[:200] if resposta_texto else f"Você está no caminho certo para alcançar seu objetivo de {request.objetivo_carreira}! Com dedicação de {request.tempo_disponivel_semana} horas por semana, você terá {request.tempo_disponivel_semana * prazo_meses * 4} horas de aprendizado. Cada etapa concluída é um passo importante na sua jornada profissional. Mantenha o foco e pratique constantemente!"
    }


@app.post("/gerar-plano-estudos", response_model=PlanoEstudosResponse)
async def gerar_plano_estudos_endpoint(request: PlanoEstudosRequest):
    """
    Endpoint principal para gerar plano de estudos.
    Pode ser usado diretamente ou importado pelo main.py
    """
    try:
        return await gerar_plano_estudos(request)
    except HTTPException:
        # Re-raise HTTPException para manter status code correto
        raise
    except Exception as e:
        # Capturar qualquer outro erro e retornar fallback
        print(f"❌ Erro inesperado no endpoint: {str(e)}")
        import traceback
        traceback.print_exc()
        # Retornar plano fallback em caso de qualquer erro
        try:
            plano_fallback_dict = criar_plano_fallback(request, "")
            return processar_resposta_gemini_fallback(plano_fallback_dict, request)
        except Exception as fallback_error:
            print(f"❌ Erro no fallback: {str(fallback_error)}")
            raise HTTPException(status_code=500, detail=f"Erro ao gerar plano de estudos: {str(e)}")


@app.get("/health")
async def health_check():
    """Health check"""
    return {
        "status": "ok",
        "servico": "IOT - Geração de Plano de Estudos",
        "modelo_ia": "Gemini 2.0 Flash"
    }

