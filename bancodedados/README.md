# SkillBridge – Banco de Dados (Oracle + MongoDB)

Projeto Global Solution FIAP 2025/2 – Tema **"O Futuro do Trabalho"**.  
Implementa o backend de dados da plataforma **SkillBridge** com Oracle (relacional) e MongoDB (NoSQL).

## 📁 Estrutura de Pastas

```
bancodedados/
├── sql/            # Scripts Oracle (DDL, packages, funções, triggers, export)
├── nosql/          # Dataset JSON, script de importação e guia do mongosh
├── docs/           # Diagramas lógico e físico (PDF)
└── README.md       # Este arquivo
```

## 🚀 Configuração Inicial - Oracle

### Pré-requisitos

- Acesso ao Oracle Database (ex: `oracle.fiap.com.br:1521/ORCL`)
- Usuário com permissões para criar tabelas, packages e triggers
- SQL Developer ou ferramenta similar

### Passo a Passo

#### 1. Executar Scripts SQL na Ordem

Conecte ao schema Oracle e execute os scripts na ordem:

1. **`sql/create_tables.sql`** - Criação das tabelas
2. **`sql/functions.sql`** - Funções PL/SQL
3. **`sql/packages.sql`** - Packages PL/SQL (`PKG_USUARIOS`, `PKG_VAGAS`)
4. **`sql/triggers.sql`** - Triggers de auditoria
5. **`sql/create_recomendacao_ia_table.sql`** - Tabela para recomendações com IA
6. **`sql/dataset_export.sql`** - Procedure para exportar dataset JSON

**Importante:** Execute na ordem indicada para evitar erros de dependência.

#### 2. Popular Dados Iniciais

Execute a procedure para popular dados temáticos:

```sql
BEGIN
  pkg_usuarios.popular_dados_iniciais;
END;
/
COMMIT;
```

**Verificar dados:**
```sql
SELECT COUNT(*) FROM usuario;
SELECT COUNT(*) FROM vaga;
SELECT COUNT(*) FROM curso;
```

#### 3. Exportar Dataset JSON (Opcional)

Para exportar dados para MongoDB:

```sql
SET SERVEROUTPUT ON;
EXEC exportar_dataset_json;
```

Copie o output e salve em `nosql/dataset.json` (já incluso no projeto).

#### 4. Testar Funções e Triggers

**Testar funções:**
```sql
-- Gerar JSON manual
SELECT fn_gerar_json_manual FROM dual;

-- Calcular compatibilidade
SELECT fn_calcular_compatibilidade('Java, SQL', 'Java, Cloud') FROM dual;
```

**Testar triggers:**
```sql
-- Verificar logs de auditoria
SELECT * FROM log_auditoria ORDER BY data_evento DESC;
```

## 🍃 Configuração - MongoDB (Opcional)

### Pré-requisitos

- MongoDB Server instalado e rodando (`mongod`)
- `mongosh` ou MongoDB Compass

### Passo a Passo

1. **Iniciar MongoDB Server:**
   ```bash
   mongod
   ```

2. **Abrir MongoDB Shell:**
   ```bash
   mongosh
   ```

3. **Importar Dataset:**
   - Siga o guia: `nosql/import_mongosh.md`
   - Ou execute: `mongoimport --db skillbridge --collection recomendacoes --file nosql/dataset.json --jsonArray`

4. **Validar Importação:**
   ```javascript
   use skillbridge;
   db.recomendacoes.find().pretty();
   ```

## 📊 Diagramas

- **Modelo Lógico**: `docs/modelo-logico.pdf`
- **Modelo Físico**: `docs/modelo-relacional.pdf`

Gerados no Oracle Data Modeler (notação IE). Representam o modelo em 3FN conforme o script `create_tables.sql`.

## 🔗 Integração com Aplicação Java

A API Java consome as procedures/funções via JDBC:

### Procedures Principais

- **`PKG_USUARIOS.INSERIR_USUARIO`** - Cadastro de usuários
- **`PKG_VAGAS.REGISTRAR_APLICACAO`** - Registro de candidaturas
- **`PKG_VAGAS.CALCULAR_COMPATIBILIDADE`** - Cálculo de compatibilidade

### Funções

- **`fn_gerar_json_manual`** - Gera JSON para exportação
- **`fn_calcular_compatibilidade`** - Calcula compatibilidade entre competências

### Triggers

Triggers de auditoria registram automaticamente:
- INSERT em `usuario`, `vaga`, `curso`, `aplicacao`
- UPDATE em `usuario`, `vaga`
- DELETE em `vaga`, `curso`

Logs salvos em `log_auditoria`.

## 📋 Scripts Disponíveis

| Script | Descrição |
|--------|-----------|
| `create_tables.sql` | Criação de todas as tabelas |
| `functions.sql` | Funções PL/SQL utilitárias |
| `packages.sql` | Packages `PKG_USUARIOS` e `PKG_VAGAS` |
| `triggers.sql` | Triggers de auditoria |
| `create_recomendacao_ia_table.sql` | Tabela para armazenar recomendações com IA |
| `dataset_export.sql` | Procedure para exportar dados em JSON |

## 🐛 Troubleshooting

### Erro ao executar scripts
- Verifique permissões do usuário Oracle
- Confirme ordem de execução dos scripts
- Verifique sintaxe SQL no SQL Developer

### Erro ao popular dados
- Execute `pkg_usuarios.popular_dados_iniciais` novamente
- Verifique constraints e foreign keys

### Triggers não funcionando
- Verifique se `triggers.sql` foi executado
- Confirme permissões para criar triggers
- Verifique tabela `log_auditoria`

## 📝 Evidências Obrigatórias

- ✅ Scripts SQL/PLSQL
- ✅ Arquivo `nosql/dataset.json` e `mongo_import.js`
- ✅ Guia `nosql/import_mongosh.md`
- ✅ Diagramas em PDF (`docs/`)
- ⚠️ Vídeo demonstrativo (gravar separadamente)

---

**Autor:** Afonso (Equipe SkillBridge) – 2025/2.
