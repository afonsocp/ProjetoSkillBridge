# 📦 Links dos Deploys e Instruções de Acesso

Este documento contém todas as informações necessárias para acessar e testar os serviços deployados do projeto SkillBridge.

---

## 🔗 Links dos Deploys

### API Java Spring Boot
**URL Base:** `https://projetojavaskillbridge.onrender.com`

**Status:** ✅ **Deploy realizado no Render**

**Documentação Swagger:** `https://projetojavaskillbridge.onrender.com/swagger-ui.html`

**Health Check:** `https://projetojavaskillbridge.onrender.com/actuator/health`

---

### Serviço IoT (Python FastAPI)
**URL Base:** `https://[SEU-DEPLOY-IOT-AQUI].railway.app` ou `https://[SEU-DEPLOY-IOT-AQUI].render.com`

**Status:** ⚠️ **Aguardando deploy** - Substitua pela URL real após fazer o deploy

**Documentação Swagger:** `https://[URL-DO-IOT]/docs`

**Health Check:** `https://[URL-DO-IOT]/health`

---

## 🔐 Credenciais e Configurações

### Banco de Dados Oracle

**URL de Conexão:**
```
jdbc:oracle:thin:@//oracle.fiap.com.br:1521/ORCL
```

**Usuário:** `RM557863`

**Senha:** `091105` ⚠️ **ATENÇÃO:** Altere esta senha em produção!

**Host:** `oracle.fiap.com.br`

**Porta:** `1521`

**SID:** `ORCL`

---

### API Keys e Tokens

#### Gemini API Key
**Chave:** `AIzaSyCuOLheV5Rc6C0V_yJArFjDFQxjyzN971s`

**Modelo:** `gemini-2.0-flash-exp`

**Como obter nova chave:**
1. Acesse: https://aistudio.google.com/apikey
2. Faça login com sua conta Google
3. Clique em "Create API Key"
4. Copie a chave gerada

⚠️ **IMPORTANTE:** Esta chave está exposta no código. Em produção, use variáveis de ambiente!

---

#### JWT Secret
**Secret:** `change-me-please-32-characters-minimum`

⚠️ **IMPORTANTE:** Altere para um secret seguro em produção (mínimo 32 caracteres)

**Expiração:** 3600000ms (1 hora)

---

## 📋 Instruções de Acesso e Testes

### 1. Testar API Java

#### Verificar se está online:
```bash
curl https://projetojavaskillbridge.onrender.com/actuator/health
```

**Resposta esperada:**
```json
{
  "status": "UP"
}
```

#### Acessar Swagger UI:
1. Abra no navegador: `https://projetojavaskillbridge.onrender.com/swagger-ui.html`
2. Explore os endpoints disponíveis
3. Teste diretamente pela interface

#### Registrar novo usuário:
```bash
curl -X POST https://projetojavaskillbridge.onrender.com/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@example.com",
    "senha": "senha123",
    "nome": "Usuário Teste",
    "cpf": "12345678900"
  }'
```

**Resposta:** Retorna um token JWT

#### Fazer login:
```bash
curl -X POST https://projetojavaskillbridge.onrender.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@example.com",
    "senha": "senha123"
  }'
```

**Resposta:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tipo": "Bearer"
}
```

#### Listar vagas (requer autenticação):
```bash
curl -X GET https://projetojavaskillbridge.onrender.com/api/v1/vagas \
  -H "Authorization: Bearer [SEU-TOKEN-JWT]"
```

---

### 2. Testar Serviço IoT

#### Verificar se está online:
```bash
curl https://[URL-DO-IOT]/health
```

**Resposta esperada:**
```json
{
  "status": "ok",
  "servico": "IOT - Geração de Plano de Estudos",
  "modelo_ia": "Gemini 2.0 Flash"
}
```

#### Acessar Swagger UI:
1. Abra no navegador: `https://[URL-DO-IOT]/docs`
2. Teste o endpoint `/gerar-plano-estudos`

#### Gerar plano de estudos:
```bash
curl -X POST https://[URL-DO-IOT]/gerar-plano-estudos \
  -H "Content-Type: application/json" \
  -d '{
    "objetivo_carreira": "Tornar-me desenvolvedor Java Sênior",
    "nivel_atual": "Intermediário",
    "competencias_atuais": ["Java", "Spring Boot", "SQL"],
    "tempo_disponivel_semana": 15,
    "prazo_meses": 6,
    "areas_interesse": ["Microservices", "Cloud Computing"]
  }'
```

---

### 3. Testar Integração Completa

#### Fluxo: API Java → Serviço IoT

1. **Obter token JWT** (via `/auth/login`)
2. **Gerar plano de estudos via API Java:**
```bash
curl -X POST https://projetojavaskillbridge.onrender.com/api/v1/planos-estudos/gerar \
  -H "Authorization: Bearer [SEU-TOKEN-JWT]" \
  -H "Content-Type: application/json" \
  -d '{
    "objetivo_carreira": "Desenvolvedor Java Sênior",
    "nivel_atual": "Intermediário",
    "competencias_atuais": ["Java", "Spring Boot"],
    "tempo_disponivel_semana": 15,
    "prazo_meses": 6
  }'
```

A API Java irá chamar automaticamente o serviço IoT.

---

## 🧪 Usando Postman

### Importar Collection
1. Abra o Postman
2. Importe o arquivo: `postman/SkillBridge.postman_collection.json`
3. Configure a variável `{{base_url}}` com a URL da API deployada
4. Execute `/auth/login` para obter token
5. Configure `{{auth_token}}` com o token recebido
6. Teste os outros endpoints

---

## 🔧 Variáveis de Ambiente para Deploy

### API Java (Spring Boot)

Configure estas variáveis no seu serviço de deploy (Heroku, Railway, Render, etc.):

```env
DB_USERNAME=RM557863
DB_PASSWORD=091105
SPRING_DATASOURCE_URL=jdbc:oracle:thin:@//oracle.fiap.com.br:1521/ORCL
SECURITY_JWT_SECRET=seu-secret-seguro-minimo-32-caracteres-aqui
SPRING_AI_GEMINI_API_KEY=AIzaSyCuOLheV5Rc6C0V_yJArFjDFQxjyzN971s
SPRING_AI_GEMINI_MODEL=gemini-2.0-flash-exp
IOT_SERVICE_URL=https://[URL-DO-SERVICO-IOT] (configure depois com a URL real do IoT)
PORT=8080
```

### Serviço IoT (Python FastAPI)

```env
GEMINI_API_KEY=AIzaSyCuOLheV5Rc6C0V_yJArFjDFQxjyzN971s
PORT=8000
```

---

## 📝 Checklist de Deploy

- [ ] API Java deployada e acessível
- [ ] Serviço IoT deployado e acessível
- [ ] Health checks funcionando
- [ ] Swagger UI acessível
- [ ] Banco de dados Oracle acessível
- [ ] Variáveis de ambiente configuradas
- [ ] Testes de autenticação funcionando
- [ ] Integração API Java ↔ IoT funcionando
- [ ] Documentação atualizada com URLs reais

---

## 🚨 Observações Importantes

1. **Segurança:**
   - ⚠️ As senhas e API keys neste documento são para **testes/acadêmicos**
   - Em produção, use variáveis de ambiente e secrets gerenciados
   - Não commite credenciais reais no Git

2. **Banco de Dados:**
   - O Oracle da FIAP pode ter restrições de acesso externo
   - Verifique se o deploy consegue acessar `oracle.fiap.com.br:1521`
   - Considere usar um banco de dados em nuvem se necessário

3. **CORS:**
   - Configure CORS adequadamente se houver frontend
   - Adicione os domínios permitidos nas configurações

4. **Monitoramento:**
   - Use `/actuator/health` para monitorar saúde da API
   - Configure alertas para downtime

---

## 📞 Suporte

Em caso de problemas:
1. Verifique os logs do deploy
2. Teste os health checks
3. Verifique as variáveis de ambiente
4. Consulte os READMEs:
   - `api/README.md`
   - `IOT/README.md`
   - `bancodedados/README.md`

---

**Última atualização:** Janeiro 2025

**Status:** 
- ✅ **API Java:** Deploy realizado no Render
- ⚠️ **Serviço IoT:** Aguardando deploy

