-------------------------------------------------------------------------------
-- Global Solution 2025/2 - SkillBridge Database (Oracle)
-- Relational schema in 3FN for theme "O Futuro do Trabalho"
-- Authoring tool: Cursor (GPT-5 Codex)
-------------------------------------------------------------------------------
-- Safety first: drop objects (optional, comment out in production)
-------------------------------------------------------------------------------
-- DROP TABLE aplicacao CASCADE CONSTRAINTS;
-- DROP TABLE vaga CASCADE CONSTRAINTS;
-- DROP TABLE curso CASCADE CONSTRAINTS;
-- DROP TABLE usuario CASCADE CONSTRAINTS;
-- DROP TABLE log_auditoria CASCADE CONSTRAINTS;
-- DROP SEQUENCE seq_log_auditoria;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Domain constraints
-------------------------------------------------------------------------------
CREATE TABLE dominio_tipo_contrato (
    codigo          VARCHAR2(30)    PRIMARY KEY,
    descricao       VARCHAR2(100)   NOT NULL
);

INSERT INTO dominio_tipo_contrato (codigo, descricao) VALUES ('CLT', 'Contrato CLT');
INSERT INTO dominio_tipo_contrato (codigo, descricao) VALUES ('PJ', 'Prestador de Serviço');
INSERT INTO dominio_tipo_contrato (codigo, descricao) VALUES ('FREELANCER', 'Contrato Freelancer');
INSERT INTO dominio_tipo_contrato (codigo, descricao) VALUES ('ESTAGIO', 'Contrato de Estágio');
COMMIT;

-------------------------------------------------------------------------------
-- Core tables
-------------------------------------------------------------------------------
CREATE TABLE usuario (
    id                  RAW(16)        DEFAULT SYS_GUID() PRIMARY KEY,
    nome                VARCHAR2(100)  NOT NULL,
    email               VARCHAR2(150)  NOT NULL,
    senha               VARCHAR2(200)  NOT NULL,
    role                VARCHAR2(30)   DEFAULT 'USER' NOT NULL,
    telefone            VARCHAR2(20),
    cidade              VARCHAR2(80),
    uf                  CHAR(2),
    competencias        VARCHAR2(500),
    objetivo_carreira   VARCHAR2(300),
    data_cadastro       DATE           DEFAULT SYSDATE NOT NULL,
    status_profissional VARCHAR2(30)   DEFAULT 'ATIVO' NOT NULL,
    CONSTRAINT uk_usuario_email UNIQUE (email),
    CONSTRAINT ck_usuario_email CHECK (REGEXP_LIKE(email,'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
    CONSTRAINT ck_usuario_status CHECK (status_profissional IN ('ATIVO','EM_TRANSICAO','INDISPONIVEL')),
    CONSTRAINT ck_usuario_role CHECK (role IN ('USER','ADMIN'))
);

CREATE TABLE curso (
    id              RAW(16)        DEFAULT SYS_GUID() PRIMARY KEY,
    nome            VARCHAR2(120)  NOT NULL,
    area            VARCHAR2(100)  NOT NULL,
    duracao_horas   NUMBER(5)      NOT NULL,
    modalidade      VARCHAR2(40)   DEFAULT 'ONLINE' NOT NULL,
    instituicao     VARCHAR2(120),
    descricao       VARCHAR2(400),
    nivel           VARCHAR2(40),
    data_criacao    DATE           DEFAULT SYSDATE NOT NULL,
    CONSTRAINT ck_curso_duracao CHECK (duracao_horas > 0),
    CONSTRAINT ck_curso_modalidade CHECK (modalidade IN ('ONLINE','PRESENCIAL','HIBRIDO'))
);

CREATE TABLE vaga (
    id                  RAW(16)        DEFAULT SYS_GUID() PRIMARY KEY,
    titulo              VARCHAR2(150)  NOT NULL,
    empresa             VARCHAR2(120)  NOT NULL,
    localidade          VARCHAR2(100),
    requisitos          VARCHAR2(500),
    responsabilidades   VARCHAR2(500),
    salario             NUMBER(10,2),
    tipo_contrato       VARCHAR2(30)   NOT NULL,
    formato_trabalho    VARCHAR2(30)   DEFAULT 'HIBRIDO' NOT NULL,
    data_publicacao     DATE           DEFAULT SYSDATE NOT NULL,
    data_encerramento   DATE,
    nivel_senioridade   VARCHAR2(30),
    CONSTRAINT ck_vaga_salario CHECK (salario IS NULL OR salario >= 0),
    CONSTRAINT fk_vaga_tipo_contrato FOREIGN KEY (tipo_contrato)
        REFERENCES dominio_tipo_contrato (codigo),
    CONSTRAINT ck_vaga_formato CHECK (formato_trabalho IN ('PRESENCIAL','REMOTO','HIBRIDO')),
    CONSTRAINT ck_vaga_datas CHECK (data_encerramento IS NULL OR data_encerramento >= data_publicacao)
);

CREATE TABLE aplicacao (
    id                        RAW(16)        DEFAULT SYS_GUID() PRIMARY KEY,
    usuario_id                RAW(16)        NOT NULL,
    vaga_id                   RAW(16)        NOT NULL,
    data_aplicacao            DATE           DEFAULT SYSDATE NOT NULL,
    status_aplicacao          VARCHAR2(30)   DEFAULT 'EM_ANALISE' NOT NULL,
    pontuacao_compatibilidade NUMBER(5,2),
    comentarios_avaliador     VARCHAR2(400),
    CONSTRAINT fk_aplicacao_usuario FOREIGN KEY (usuario_id)
        REFERENCES usuario (id),
    CONSTRAINT fk_aplicacao_vaga FOREIGN KEY (vaga_id)
        REFERENCES vaga (id),
    CONSTRAINT uk_aplicacao UNIQUE (usuario_id, vaga_id),
    CONSTRAINT ck_aplicacao_status CHECK (status_aplicacao IN ('EM_ANALISE','APROVADO','REPROVADO','ENTREVISTA','CONTRATADO')),
    CONSTRAINT ck_aplicacao_pontuacao CHECK (pontuacao_compatibilidade IS NULL OR (pontuacao_compatibilidade BETWEEN 0 AND 100))
);

CREATE TABLE usuario_curso (
    id              RAW(16)        DEFAULT SYS_GUID() PRIMARY KEY,
    usuario_id      RAW(16)        NOT NULL,
    curso_id        RAW(16)        NOT NULL,
    progresso       NUMBER(5,2)    DEFAULT 0 NOT NULL,
    data_inscricao  DATE           DEFAULT SYSDATE NOT NULL,
    data_conclusao  DATE,
    CONSTRAINT fk_usuario_curso_usuario FOREIGN KEY (usuario_id)
        REFERENCES usuario (id),
    CONSTRAINT fk_usuario_curso_curso FOREIGN KEY (curso_id)
        REFERENCES curso (id),
    CONSTRAINT uk_usuario_curso UNIQUE (usuario_id, curso_id),
    CONSTRAINT ck_usuario_curso_progresso CHECK (progresso BETWEEN 0 AND 100),
    CONSTRAINT ck_usuario_curso_datas CHECK (data_conclusao IS NULL OR data_conclusao >= data_inscricao)
);

CREATE TABLE log_auditoria (
    id              NUMBER          GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    tabela          VARCHAR2(100)   NOT NULL,
    acao            VARCHAR2(20)    NOT NULL,
    descricao       VARCHAR2(400),
    usuario_execucao VARCHAR2(100),
    data_evento     DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT ck_log_auditoria_acao CHECK (acao IN ('INSERT','UPDATE','DELETE'))
);

CREATE TABLE recomendacao_ia (
    id                  RAW(16)        DEFAULT SYS_GUID() PRIMARY KEY,
    usuario_id          RAW(16)        NOT NULL,
    resumo_perfil       CLOB,
    plano_carreira      CLOB,
    cursos_recomendados CLOB,
    vagas_recomendadas  CLOB,
    json_completo       CLOB,
    data_geracao        DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_recomendacao_ia_usuario FOREIGN KEY (usuario_id)
        REFERENCES usuario (id) ON DELETE CASCADE
);

CREATE INDEX ix_recomendacao_ia_usuario ON recomendacao_ia (usuario_id);
CREATE INDEX ix_recomendacao_ia_data ON recomendacao_ia (data_geracao DESC);

COMMENT ON TABLE recomendacao_ia IS 'Recomendações de carreira geradas pela IA Gemini para cada usuário';
COMMENT ON COLUMN recomendacao_ia.json_completo IS 'JSON completo retornado pela API do Gemini';
COMMENT ON COLUMN recomendacao_ia.cursos_recomendados IS 'Array JSON com IDs e detalhes dos cursos recomendados';
COMMENT ON COLUMN recomendacao_ia.vagas_recomendadas IS 'Array JSON com IDs e detalhes das vagas recomendadas';

COMMIT;

-------------------------------------------------------------------------------
-- Helpful indexes
-------------------------------------------------------------------------------
CREATE INDEX ix_usuario_nome ON usuario (nome);
CREATE INDEX ix_vaga_titulo ON vaga (titulo);
CREATE INDEX ix_vaga_empresa ON vaga (empresa);
CREATE INDEX ix_aplicacao_usuario ON aplicacao (usuario_id);
CREATE INDEX ix_aplicacao_vaga ON aplicacao (vaga_id);
CREATE INDEX ix_usuario_curso_usuario ON usuario_curso (usuario_id);

-------------------------------------------------------------------------------
-- Comments (data dictionary metadata)
-------------------------------------------------------------------------------
COMMENT ON TABLE usuario IS 'Profissionais cadastrados na SkillBridge';
COMMENT ON COLUMN usuario.status_profissional IS 'Situacao profissional atual do usuario';
COMMENT ON COLUMN usuario.senha IS 'Hash (BCrypt) da senha utilizada pela API Java';
COMMENT ON COLUMN usuario.role IS 'Papel do usuario para Spring Security (USER, ADMIN)';

COMMENT ON TABLE curso IS 'Cursos de requalificacao recomendados pela plataforma';
COMMENT ON COLUMN curso.modalidade IS 'Modalidade de participacao do curso';

COMMENT ON TABLE vaga IS 'Oportunidades de trabalho cadastradas pelas empresas parceiras';
COMMENT ON COLUMN vaga.tipo_contrato IS 'Tipo de contrato conforme dominio pre-cadastrado';

COMMENT ON TABLE aplicacao IS 'Relacao de candidaturas dos usuarios as vagas';
COMMENT ON COLUMN aplicacao.pontuacao_compatibilidade IS 'Pontuacao calculada com IA para a compatibilidade usuario-vaga';

COMMENT ON TABLE usuario_curso IS 'Historico de cursos em que o usuario esta inscrito ou concluiu';
COMMENT ON COLUMN usuario_curso.progresso IS 'Percentual de progresso do usuario no curso';

COMMENT ON TABLE log_auditoria IS 'Registro de auditoria de operações DML nas tabelas críticas';

-------------------------------------------------------------------------------
-- Commit metadata inserts
-------------------------------------------------------------------------------
COMMIT;


