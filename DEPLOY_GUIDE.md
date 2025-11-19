# 🚀 Guia Rápido de Deploy

Este guia mostra como fazer deploy da **API Java** e do **Serviço IoT Python** separadamente.

---

## 📋 Resumo

Você precisa fazer **2 deploys separados**:

1. ✅ **API Java** (Spring Boot) → Deploy 1
2. ✅ **Serviço IoT Python** (FastAPI) → Deploy 2

---

## 🎯 Opção 1: Railway (Recomendado)

### Deploy da API Java

1. **Acesse:** https://railway.app
2. **Crie conta** (pode usar GitHub)
3. **New Project** → **Deploy from GitHub repo**
4. **Selecione seu repositório** e a pasta `api/`
5. **Configure variáveis de ambiente:**
   ```
   DB_USERNAME=RM557863
   DB_PASSWORD=091105
   SPRING_DATASOURCE_URL=jdbc:oracle:thin:@//oracle.fiap.com.br:1521/ORCL
   SECURITY_JWT_SECRET=seu-secret-seguro-minimo-32-caracteres-aqui
   SPRING_AI_GEMINI_API_KEY=AIzaSyCuOLheV5Rc6C0V_yJArFjDFQxjyzN971s
   SPRING_AI_GEMINI_MODEL=gemini-2.0-flash-exp
   IOT_SERVICE_URL=https://[URL-DO-IOT-AQUI] (configure depois)
   PORT=8080
   ```
6. **Railway detecta automaticamente** que é Java/Maven
7. **Anote a URL gerada** (ex: `https://skillbridge-api.up.railway.app`)

### Deploy do Serviço IoT Python

1. **No mesmo projeto Railway** → **New Service** → **GitHub Repo**
2. **Selecione a pasta** `IOT/GlobalSolutionIOT/`
3. **Configure variáveis de ambiente:**
   ```
   GEMINI_API_KEY=AIzaSyCuOLheV5Rc6C0V_yJArFjDFQxjyzN971s
   PORT=8000
   ```
4. **Railway detecta Python** automaticamente
5. **Anote a URL gerada** (ex: `https://skillbridge-iot.up.railway.app`)

### ⚠️ IMPORTANTE: Conectar os serviços

1. **Copie a URL do IoT** (ex: `https://skillbridge-iot.up.railway.app`)
2. **Volte para o deploy da API Java**
3. **Atualize a variável:**
   ```
   IOT_SERVICE_URL=https://skillbridge-iot.up.railway.app
   ```
4. **Redeploy da API Java** para aplicar a mudança

---

## 🎯 Opção 2: Render

### Deploy da API Java

1. **Acesse:** https://render.com
2. **Crie conta** (pode usar GitHub)
3. **New** → **Web Service**
4. **Conecte seu repositório**
5. **Configurações:**
   - **Name:** `skillbridge-api`
   - **Root Directory:** `api`
   - **Build Command:** `mvn clean install`
   - **Start Command:** `java -jar target/*.jar`
   - **Environment:** `Java`
6. **Adicione variáveis de ambiente** (mesmas do Railway)
7. **Deploy**

### Deploy do Serviço IoT Python

1. **New** → **Web Service**
2. **Configurações:**
   - **Name:** `skillbridge-iot`
   - **Root Directory:** `IOT/GlobalSolutionIOT`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Environment:** `Python 3`
3. **Adicione variáveis de ambiente:**
   ```
   GEMINI_API_KEY=AIzaSyCuOLheV5Rc6C0V_yJArFjDFQxjyzN971s
   ```
4. **Deploy**

---

## 🎯 Opção 3: Heroku

### Deploy da API Java

1. **Instale Heroku CLI:** https://devcenter.heroku.com/articles/heroku-cli
2. **Login:** `heroku login`
3. **Crie app:** `heroku create skillbridge-api`
4. **Configure buildpack:**
   ```bash
   heroku buildpacks:set heroku/java -a skillbridge-api
   ```
5. **Configure variáveis:**
   ```bash
   heroku config:set DB_USERNAME=RM557863 -a skillbridge-api
   heroku config:set DB_PASSWORD=091105 -a skillbridge-api
   heroku config:set SPRING_DATASOURCE_URL="jdbc:oracle:thin:@//oracle.fiap.com.br:1521/ORCL" -a skillbridge-api
   heroku config:set SECURITY_JWT_SECRET="seu-secret-seguro-minimo-32-caracteres" -a skillbridge-api
   heroku config:set SPRING_AI_GEMINI_API_KEY=AIzaSyCuOLheV5Rc6C0V_yJArFjDFQxjyzN971s -a skillbridge-api
   heroku config:set SPRING_AI_GEMINI_MODEL=gemini-2.0-flash-exp -a skillbridge-api
   ```
6. **Deploy:**
   ```bash
   cd api
   git push heroku main
   ```

### Deploy do Serviço IoT Python

1. **Crie app:** `heroku create skillbridge-iot`
2. **Configure buildpack:**
   ```bash
   heroku buildpacks:set heroku/python -a skillbridge-iot
   ```
3. **Crie `Procfile`** em `IOT/GlobalSolutionIOT/Procfile`:
   ```
   web: uvicorn main:app --host 0.0.0.0 --port $PORT
   ```
4. **Configure variáveis:**
   ```bash
   heroku config:set GEMINI_API_KEY=AIzaSyCuOLheV5Rc6C0V_yJArFjDFQxjyzN971s -a skillbridge-iot
   ```
5. **Deploy:**
   ```bash
   cd IOT/GlobalSolutionIOT
   git push heroku main
   ```

---

## ✅ Após os Deploys

### 1. Testar os serviços

**API Java:**
```bash
curl https://[URL-DA-API]/actuator/health
```

**Serviço IoT:**
```bash
curl https://[URL-DO-IOT]/health
```

### 2. Atualizar documentação

Edite `IOT/DEPLOY.md` e substitua:
- `[URL-DA-API]` → URL real da API Java
- `[URL-DO-IOT]` → URL real do serviço IoT

### 3. Configurar integração

Certifique-se de que a API Java tem a variável:
```
IOT_SERVICE_URL=https://[URL-DO-IOT]
```

---

## 🐛 Troubleshooting

### API Java não conecta ao banco Oracle
- Verifique se `oracle.fiap.com.br:1521` é acessível da internet
- Oracle da FIAP pode ter firewall bloqueando conexões externas
- **Solução:** Use um banco Oracle em nuvem (Oracle Cloud, AWS RDS) ou tunel SSH

### Serviço IoT não responde
- Verifique se `GEMINI_API_KEY` está configurada
- Verifique logs do deploy
- Teste localmente primeiro: `python -m uvicorn main:app --port 8000`

### API Java não encontra serviço IoT
- Verifique se `IOT_SERVICE_URL` está correto
- Teste a URL do IoT diretamente no navegador
- Verifique se ambos os serviços estão online

---

## 📝 Checklist Final

- [ ] API Java deployada e acessível
- [ ] Serviço IoT deployado e acessível
- [ ] Health checks funcionando em ambos
- [ ] Variável `IOT_SERVICE_URL` configurada na API Java
- [ ] URLs atualizadas em `IOT/DEPLOY.md`
- [ ] Testes de integração funcionando

---

**Dica:** Railway é a opção mais simples e rápida para começar! 🚀

