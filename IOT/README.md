# IOT - Módulo de Deep Learning (IA Generativa)

Módulo Python/FastAPI que implementa **IA Generativa** usando Google Gemini para gerar planos de estudos personalizados. Integrado com a API Java Spring Boot.

## 📋 Descrição

Este módulo utiliza **Google Gemini API** para gerar planos de estudos personalizados baseados no perfil do usuário, demonstrando:
- ✅ Integração com IA Generativa (Gemini)
- ✅ Prompt Engineering avançado
- ✅ Geração de conteúdo estruturado em JSON
- ✅ Integração via REST API com Java

## 🚀 Pré-requisitos

- **Python 3.10+** instalado
- **Chave da API Gemini** (obtenha em: https://aistudio.google.com/apikey)

## 📦 Instalação

### 1. Instalar Dependências

```bash
cd IOT/GlobalSolutionIOT
pip install -r requirements.txt
```

**Dependências principais:**
- `fastapi` - Framework web
- `uvicorn` - Servidor ASGI
- `google-genai` - Cliente Gemini API
- `pydantic` - Validação de dados
- `python-dotenv` - Gerenciamento de variáveis de ambiente

### 2. Configurar Chave da API Gemini

Crie arquivo `.env` na pasta `IOT/GlobalSolutionIOT/`:

```env
GEMINI_API_KEY=sua-chave-gemini-aqui
```

**Como obter a chave:**
1. Acesse: https://aistudio.google.com/apikey
2. Faça login com sua conta Google
3. Clique em "Create API Key"
4. Copie a chave gerada (formato: `AIzaSy...`)

## ▶️ Como Executar

### Opção 1: Executar via main.py (Recomendado)

```bash
cd IOT/GlobalSolutionIOT
python -m uvicorn main:app --reload --port 8000
```

### Opção 2: Executar módulo diretamente

```bash
cd IOT/GlobalSolutionIOT
python -m uvicorn gerar_plano_estudos:app --reload --port 8000
```

### Verificar se está rodando

```bash
curl http://localhost:8000/health
```

**Resposta esperada:**
```json
{
  "status": "ok",
  "servico": "IOT - Geração de Plano de Estudos",
  "modelo_ia": "Gemini 2.0 Flash"
}
```

## 📡 Endpoints Disponíveis

### POST `/gerar-plano-estudos`

Gera plano de estudos personalizado usando IA Generativa (Gemini).

**Request Body:**
```json
{
  "objetivo_carreira": "Tornar-me desenvolvedor Java Sênior",
  "nivel_atual": "Intermediário",
  "competencias_atuais": ["Java", "Spring Boot", "SQL"],
  "tempo_disponivel_semana": 15,
  "prazo_meses": 6,
  "areas_interesse": ["Microservices", "Cloud Computing"]
}
```

**Response:**
```json
{
  "objetivo_carreira": "Tornar-me desenvolvedor Java Sênior",
  "nivel_atual": "Intermediário",
  "prazo_total_meses": 6,
  "horas_totais_estimadas": 360,
  "etapas": [
    {
      "ordem": 1,
      "titulo": "Fundamentos e Base Sólida",
      "descricao": "Estabeleça uma base sólida em Java, Spring Boot...",
      "duracao_semanas": 8,
      "recursos_sugeridos": [
        "Curso: Java Completo (Udemy)",
        "Documentação oficial: Oracle Java Documentation"
      ],
      "competencias_desenvolvidas": ["Java", "Spring Boot"]
    }
  ],
  "recursos_adicionais": [
    "Comunidades online (Stack Overflow, Reddit)",
    "Certificações profissionais"
  ],
  "metricas_sucesso": [
    "Conclusão de projetos práticos",
    "Aplicação do conhecimento em situações reais"
  ],
  "motivacao": "Você está no caminho certo para alcançar seu objetivo..."
}
```

### GET `/health`

Verifica saúde do serviço.

## 🔗 Integração com API Java

A API Java chama este serviço via REST:

```
API Java → POST http://localhost:8000/gerar-plano-estudos → Resposta JSON
```

**Endpoint na API Java:**
```
POST /api/v1/planos-estudos/gerar
```

**Configuração na API Java** (`application.properties`):
```properties
iot.service.url=http://localhost:8000
```

**Fluxo completo:**
1. Cliente faz requisição para API Java: `POST /api/v1/planos-estudos/gerar`
2. API Java chama serviço Python: `POST http://localhost:8000/gerar-plano-estudos`
3. Serviço Python chama Gemini API
4. Resposta retorna via Java → Cliente

## 🧠 Como Funciona a IA

### Prompt Engineering

O sistema constrói prompts estruturados com:
- Perfil do usuário (objetivo, nível, competências)
- Tempo disponível e prazo
- Áreas de interesse
- Instruções claras para geração de JSON estruturado

### Tratamento de Erros

- **Quota excedida**: Sistema usa fallback inteligente
- **API indisponível**: Retorna plano básico baseado no perfil
- **Resposta inválida**: Processa e estrutura resposta manualmente

### Logs Detalhados

O sistema registra:
- Tentativa de chamada ao Gemini
- Chave API sendo usada (parcialmente mascarada)
- Sucesso ou erro na chamada
- Uso de fallback quando necessário

## 📝 Documentação Swagger

Após iniciar o servidor, acesse:

```
http://localhost:8000/docs
```

Interface interativa para testar os endpoints.

## 🐛 Troubleshooting

### Erro: "GEMINI_API_KEY não encontrada"
- Verifique se arquivo `.env` existe em `IOT/GlobalSolutionIOT/`
- Confirme que a variável está escrita corretamente: `GEMINI_API_KEY=...`
- Reinicie o servidor após criar/editar o `.env`

### Erro 429: Quota Excedida
- A quota gratuita do Gemini tem limites
- O sistema usa fallback automático
- Aguarde alguns minutos ou use outra conta Google

### Erro ao chamar do Java
- Verifique se servidor Python está rodando: `curl http://localhost:8000/health`
- Confirme `iot.service.url` na API Java
- Verifique logs do servidor Python

### Porta 8000 já em uso
```bash
# Windows PowerShell
netstat -ano | findstr :8000
# Pare o processo ou use outra porta:
python -m uvicorn main:app --reload --port 8001
```

## 📁 Estrutura do Projeto

```
IOT/
├── GlobalSolutionIOT/
│   ├── main.py                    # Aplicação FastAPI principal
│   ├── gerar_plano_estudos.py     # Módulo de geração de planos
│   ├── requirements.txt           # Dependências Python
│   └── .env                       # Variáveis de ambiente (criar)
└── README.md                      # Este arquivo
```

## ✅ Requisitos Atendidos

- ✅ **IA Generativa**: Gemini API para geração de texto
- ✅ **Prompt Engineering**: Prompts estruturados e personalizados
- ✅ **Integração com Java**: REST API funcional
- ✅ **Deep Learning**: Modelo de IA aplicado
- ✅ **Tratamento de Erros**: Fallback inteligente
- ✅ **Documentação**: README completo + Swagger

## 📚 Tecnologias

- **Python 3.10+**
- **FastAPI** - Framework web moderno
- **Google Gemini API** - IA Generativa
- **Pydantic** - Validação de dados
- **Uvicorn** - Servidor ASGI

---

**IOT Module – Gerando planos de estudos personalizados com IA Generativa.**
