# SkillBridge - Projeto Global Solution FIAP

Plataforma de capacitação profissional voltada à transição energética. Conecta talentos a cursos e vagas sustentáveis utilizando IA generativa para sugerir próximos passos em requalificação.

## 📁 Estrutura do Projeto

```
ProjetoGS/
├── api/                    # API Java Spring Boot
├── bancodedados/          # Scripts Oracle e MongoDB
├── IOT/                   # Módulo Python (Deep Learning)
└── postman/               # Coleção Postman para testes
```

## 🚀 Início Rápido

### 1. Banco de Dados (Oracle)

```bash
cd bancodedados
# Execute os scripts SQL na ordem (ver README.md)
```

**Ver:** `bancodedados/README.md` para instruções detalhadas.

### 2. API Java

```bash
cd api
# Configure application.properties
mvn spring-boot:run
```

**Ver:** `api/README.md` para instruções completas.

### 3. Servidor IOT (Python)

```bash
cd IOT/GlobalSolutionIOT
# Configure arquivo .env com GEMINI_API_KEY
pip install -r requirements.txt
python -m uvicorn main:app --reload --port 8000
```

**Ver:** `IOT/README.md` para instruções completas.

## 📚 Documentação

- **API Java**: `api/README.md`
- **Banco de Dados**: `bancodedados/README.md`
- **IOT (Deep Learning)**: `IOT/README.md`
- **Postman Collection**: `postman/SkillBridge.postman_collection.json`

## 🔗 Integração entre Módulos

```
Cliente → API Java (8080) → Servidor IOT Python (8000) → Gemini API
                ↓
          Oracle Database
```

## 🧪 Testes

### API Java
```bash
cd api
mvn test
```

### Postman
Importe `postman/SkillBridge.postman_collection.json` e configure:
- `{{base_url}}` = `http://localhost:8080`
- Obtenha token via `/auth/login` e configure `{{auth_token}}`

## 📋 Pré-requisitos

- Java 21
- Maven 3.9+
- Python 3.10+
- Oracle Database (acessível)
- Chave API Gemini (https://aistudio.google.com/apikey)

## 🎯 Funcionalidades Principais

- ✅ Autenticação JWT
- ✅ Gerenciamento de usuários, vagas e cursos
- ✅ Cálculo de compatibilidade usuário × vaga
- ✅ Recomendações com IA (Gemini)
- ✅ Geração de planos de estudos personalizados
- ✅ Integração Oracle via PL/SQL
- ✅ Cache e internacionalização

---

**SkillBridge – conectando talentos, habilidades e oportunidades no futuro da energia.**

