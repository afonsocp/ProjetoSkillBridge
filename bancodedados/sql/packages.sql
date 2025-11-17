-------------------------------------------------------------------------------
-- Global Solution 2025/2 - SkillBridge Database (Oracle)
-- PL/SQL Packages
-------------------------------------------------------------------------------
SET DEFINE OFF;

-------------------------------------------------------------------------------
-- Package: PKG_VAGAS
-- Responsavel por logica de vagas e compatibilidade
-------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_vagas AS
  FUNCTION calcular_compatibilidade(p_usuario_id RAW, p_vaga_id RAW) RETURN NUMBER;

  PROCEDURE inserir_vaga(
    p_titulo        VARCHAR2,
    p_empresa       VARCHAR2,
    p_requisitos    VARCHAR2,
    p_salario       NUMBER,
    p_tipo          VARCHAR2,
    p_localidade    VARCHAR2 DEFAULT NULL,
    p_formato       VARCHAR2 DEFAULT 'HIBRIDO',
    p_nivel         VARCHAR2 DEFAULT NULL,
    p_responsabilidades VARCHAR2 DEFAULT NULL
  );

  PROCEDURE registrar_aplicacao(
    p_usuario_id    RAW,
    p_vaga_id       RAW,
    p_status        VARCHAR2 DEFAULT 'EM_ANALISE',
    p_pontuacao     NUMBER DEFAULT NULL,
    p_comentario    VARCHAR2 DEFAULT NULL
  );
END pkg_vagas;
/

CREATE OR REPLACE PACKAGE BODY pkg_vagas AS
  FUNCTION normalizar_texto(p_texto VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN LOWER(REPLACE(p_texto, ' ', ''));
  END normalizar_texto;

  FUNCTION calcular_compatibilidade(p_usuario_id RAW, p_vaga_id RAW) RETURN NUMBER IS
    v_competencias_usuario VARCHAR2(500);
    v_requisitos_vaga      VARCHAR2(500);
    v_match_count          NUMBER := 0;
    v_total_requisitos     NUMBER := 0;
  BEGIN
    SELECT NVL(competencias,''), NVL(requisitos,'')
      INTO v_competencias_usuario, v_requisitos_vaga
      FROM usuario u CROSS JOIN vaga v
     WHERE u.id = p_usuario_id
       AND v.id = p_vaga_id;

    IF v_requisitos_vaga IS NULL OR v_requisitos_vaga = '' THEN
      RETURN 100;
    END IF;

    FOR req IN (SELECT REGEXP_SUBSTR(v_requisitos_vaga, '[^,]+', 1, LEVEL) requisito
                  FROM dual
                CONNECT BY REGEXP_SUBSTR(v_requisitos_vaga, '[^,]+', 1, LEVEL) IS NOT NULL)
    LOOP
      v_total_requisitos := v_total_requisitos + 1;

      IF INSTR(normalizar_texto(v_competencias_usuario),
               normalizar_texto(req.requisito)) > 0 THEN
        v_match_count := v_match_count + 1;
      END IF;
    END LOOP;

    IF v_total_requisitos = 0 THEN
      RETURN 0;
    END IF;

    RETURN ROUND((v_match_count / v_total_requisitos) * 100, 2);
  EXCEPTION
    WHEN no_data_found THEN
      RAISE_APPLICATION_ERROR(-20031, 'Usuario ou vaga nao encontrados para compatibilidade.');
  END calcular_compatibilidade;

  PROCEDURE inserir_vaga(
    p_titulo        VARCHAR2,
    p_empresa       VARCHAR2,
    p_requisitos    VARCHAR2,
    p_salario       NUMBER,
    p_tipo          VARCHAR2,
    p_localidade    VARCHAR2,
    p_formato       VARCHAR2,
    p_nivel         VARCHAR2,
    p_responsabilidades VARCHAR2
  ) AS
    v_dummy NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_dummy
      FROM dominio_tipo_contrato
     WHERE codigo = p_tipo;

    IF v_dummy = 0 THEN
      RAISE_APPLICATION_ERROR(-20032, 'Tipo de contrato inexistente: ' || p_tipo);
    END IF;

    INSERT INTO vaga (
      titulo, empresa, requisitos, salario, tipo_contrato,
      localidade, formato_trabalho, nivel_senioridade, responsabilidades
    )
    VALUES (
      p_titulo, p_empresa, p_requisitos, p_salario, p_tipo,
      p_localidade, p_formato, p_nivel, p_responsabilidades
    );
  END inserir_vaga;

  PROCEDURE registrar_aplicacao(
    p_usuario_id    RAW,
    p_vaga_id       RAW,
    p_status        VARCHAR2
  ) AS
    v_comp NUMBER;
  BEGIN
    v_comp := calcular_compatibilidade(p_usuario_id, p_vaga_id);

    INSERT INTO aplicacao (
      usuario_id,
      vaga_id,
      status_aplicacao,
      pontuacao_compatibilidade
    ) VALUES (
      p_usuario_id,
      p_vaga_id,
      p_status,
      v_comp
    );
  EXCEPTION
    WHEN dup_val_on_index THEN
      RAISE_APPLICATION_ERROR(-20033, 'O usuario ja possui candidatura para esta vaga.');
  END registrar_aplicacao;
END pkg_vagas;
/

-------------------------------------------------------------------------------
-- Package: PKG_AUDITORIA
-- Responsavel por registros de auditoria
-------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_auditoria AS
  PROCEDURE registrar_evento(
    p_tabela    VARCHAR2,
    p_acao      VARCHAR2,
    p_descricao VARCHAR2,
    p_usuario   VARCHAR2 DEFAULT SYS_CONTEXT('USERENV','SESSION_USER')
  );

  FUNCTION obter_logs_recente(p_limite NUMBER DEFAULT 20) RETURN SYS_REFCURSOR;
END pkg_auditoria;
/

CREATE OR REPLACE PACKAGE BODY pkg_auditoria AS
  PROCEDURE registrar_evento(
    p_tabela    VARCHAR2,
    p_acao      VARCHAR2,
    p_descricao VARCHAR2,
    p_usuario   VARCHAR2
  ) AS
  BEGIN
    INSERT INTO log_auditoria (tabela, acao, descricao, usuario_execucao)
    VALUES (SUBSTR(p_tabela,1,100), SUBSTR(p_acao,1,20), SUBSTR(p_descricao,1,400), SUBSTR(p_usuario,1,100));
  END registrar_evento;

  FUNCTION obter_logs_recente(p_limite NUMBER) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT *
        FROM (
          SELECT id, tabela, acao, descricao, usuario_execucao, data_evento
            FROM log_auditoria
           ORDER BY data_evento DESC
        )
       WHERE ROWNUM <= NVL(p_limite, 20);

    RETURN v_cursor;
  END obter_logs_recente;
END pkg_auditoria;
/

-------------------------------------------------------------------------------
-- Package: PKG_USUARIOS
-- Responsavel por operacoes relacionadas a usuarios e cursos
-------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_usuarios AS
  PROCEDURE inserir_usuario(
    p_nome          VARCHAR2,
    p_email         VARCHAR2,
    p_competencias  VARCHAR2,
    p_telefone      VARCHAR2 DEFAULT NULL,
    p_cidade        VARCHAR2 DEFAULT NULL,
    p_uf            VARCHAR2 DEFAULT NULL,
    p_objetivo      VARCHAR2 DEFAULT NULL
  );

  PROCEDURE inserir_vaga(
    p_titulo        VARCHAR2,
    p_empresa       VARCHAR2,
    p_requisitos    VARCHAR2,
    p_salario       NUMBER,
    p_tipo          VARCHAR2,
    p_localidade    VARCHAR2 DEFAULT NULL,
    p_formato       VARCHAR2 DEFAULT 'HIBRIDO',
    p_nivel         VARCHAR2 DEFAULT NULL,
    p_responsabilidades VARCHAR2 DEFAULT NULL
  );

  PROCEDURE popular_dados_iniciais;

  PROCEDURE associar_usuario_curso(
    p_usuario_id    RAW,
    p_curso_id      RAW
  );

  FUNCTION obter_json_usuario(p_usuario_id RAW) RETURN CLOB;
END pkg_usuarios;
/

CREATE OR REPLACE PACKAGE BODY pkg_usuarios AS
  fk_violation EXCEPTION;
  PRAGMA EXCEPTION_INIT(fk_violation, -2291);

  PROCEDURE validar_email(p_email VARCHAR2) IS
  BEGIN
    IF NOT REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
      RAISE_APPLICATION_ERROR(-20001, 'E-mail invalido: ' || p_email);
    END IF;
  END validar_email;

  PROCEDURE inserir_usuario(
    p_nome          VARCHAR2,
    p_email         VARCHAR2,
    p_competencias  VARCHAR2,
    p_telefone      VARCHAR2,
    p_cidade        VARCHAR2,
    p_uf            VARCHAR2,
    p_objetivo      VARCHAR2
  ) AS
  BEGIN
    validar_email(p_email);

    INSERT INTO usuario (nome, email, competencias, telefone, cidade, uf, objetivo_carreira)
    VALUES (p_nome, p_email, p_competencias, p_telefone, p_cidade, p_uf, p_objetivo);
  EXCEPTION
    WHEN dup_val_on_index THEN
      RAISE_APPLICATION_ERROR(-20011, 'Ja existe um usuario com o e-mail informado.');
  END inserir_usuario;

  PROCEDURE inserir_vaga(
    p_titulo        VARCHAR2,
    p_empresa       VARCHAR2,
    p_requisitos    VARCHAR2,
    p_salario       NUMBER,
    p_tipo          VARCHAR2,
    p_localidade    VARCHAR2,
    p_formato       VARCHAR2,
    p_nivel         VARCHAR2,
    p_responsabilidades VARCHAR2
  ) AS
  BEGIN
    pkg_vagas.inserir_vaga(
      p_titulo,
      p_empresa,
      p_requisitos,
      p_salario,
      p_tipo,
      p_localidade,
      p_formato,
      p_nivel,
      p_responsabilidades
    );
  END inserir_vaga;

  PROCEDURE popular_dados_iniciais AS
    TYPE t_curso_seed IS RECORD (
      nome          VARCHAR2(120),
      area          VARCHAR2(100),
      duracao       NUMBER,
      modalidade    VARCHAR2(40),
      instituicao   VARCHAR2(120),
      descricao     VARCHAR2(400),
      nivel         VARCHAR2(40)
    );
    TYPE t_curso_tab IS TABLE OF t_curso_seed;
    v_cursos t_curso_tab := t_curso_tab(
      t_curso_seed('Imersao em Inteligencia Artificial', 'Tecnologia', 60, 'ONLINE', 'SkillBridge Academy', 'Fundamentos de IA para requalificacao profissional', 'Intermediario'),
      t_curso_seed('Soft Skills para o Futuro do Trabalho', 'Desenvolvimento Humano', 24, 'ONLINE', 'SkillBridge Academy', 'Habilidades comportamentais para ambientes digitais', 'Basico'),
      t_curso_seed('Automacao com RPA', 'Tecnologia', 32, 'HIBRIDO', 'FIAP', 'Criacao de automacoes para rotinas operacionais', 'Intermediario'),
      t_curso_seed('Analytics para Gestores de Talentos', 'Dados', 36, 'ONLINE', 'SkillBridge Academy', 'Analise de dados aplicada a RH estrategico', 'Intermediario'),
      t_curso_seed('Cloud Computing para Desenvolvedores', 'Tecnologia', 48, 'ONLINE', 'SkillBridge Academy', 'Arquitetura de microsservicos e cloud native', 'Avancado'),
      t_curso_seed('Ciberseguranca para Empresas Hibridas', 'Tecnologia', 30, 'ONLINE', 'SkillBridge Academy', 'Seguranca digital em ambientes remotos', 'Intermediario'),
      t_curso_seed('Gestao Agile de Carreiras', 'Gestao', 20, 'ONLINE', 'SkillBridge Academy', 'Metodologias ageis aplicadas a gestao de talentos', 'Basico'),
      t_curso_seed('Data Engineering com Spark', 'Dados', 54, 'ONLINE', 'FIAP', 'Pipelines de dados escalaveis para IA', 'Avancado'),
      t_curso_seed('UX para Produtos de IA', 'Design', 28, 'ONLINE', 'SkillBridge Academy', 'Experiencias centradas no humano em solucoes de IA', 'Intermediario'),
      t_curso_seed('Machine Learning para RH', 'Dados', 42, 'ONLINE', 'SkillBridge Academy', 'Modelos preditivos para jornada do colaborador', 'Avancado')
    );

    TYPE t_usuario_seed IS RECORD (
      nome          VARCHAR2(100),
      email         VARCHAR2(150),
      competencias  VARCHAR2(500),
      telefone      VARCHAR2(20),
      cidade        VARCHAR2(80),
      uf            VARCHAR2(2),
      objetivo      VARCHAR2(300)
    );
    TYPE t_usuario_tab IS TABLE OF t_usuario_seed;
    v_usuarios t_usuario_tab := t_usuario_tab(
      t_usuario_seed('Afonso Pereira', 'afonso.pereira@skillbridge.com', 'Java, Spring Boot, SQL, Microservices', '11988880001', 'Sao Paulo', 'SP', 'Migrar para arquitetura de IA corporativa'),
      t_usuario_seed('Bianca Rodrigues', 'bianca.rodrigues@skillbridge.com', 'Python, Data Analysis, Power BI, SQL', '11988880002', 'Campinas', 'SP', 'Atuar como cientista de dados em people analytics'),
      t_usuario_seed('Carlos Lima', 'carlos.lima@skillbridge.com', 'UX, UI, Figma, Design Thinking', '11988880003', 'Rio de Janeiro', 'RJ', 'Especializar-se em UX para produtos com IA'),
      t_usuario_seed('Daniela Martins', 'daniela.martins@skillbridge.com', 'Scrum, Kanban, OKRs, Lideranca', '11988880004', 'Belo Horizonte', 'MG', 'Liderar squads de requalificacao digital'),
      t_usuario_seed('Emanuel Souza', 'emanuel.souza@skillbridge.com', 'DevOps, Kubernetes, AWS, Terraform', '11988880005', 'Curitiba', 'PR', 'Aprimorar conhecimento em cloud para IA'),
      t_usuario_seed('Fernanda Alves', 'fernanda.alves@skillbridge.com', 'Ciberseguranca, ISO27001, Zero Trust', '11988880006', 'Recife', 'PE', 'Implementar estrategias de seguranca em ambientes hibridos'),
      t_usuario_seed('Gustavo Ferreira', 'gustavo.ferreira@skillbridge.com', 'RPA, Automacao, VBA, Python', '11988880007', 'Porto Alegre', 'RS', 'Automatizar processos de RH com RPA'),
      t_usuario_seed('Helena Moraes', 'helena.moraes@skillbridge.com', 'People Analytics, SQL, storytelling', '11988880008', 'Florianopolis', 'SC', 'Desenvolver carreira em analytics aplicada a RH'),
      t_usuario_seed('Igor Santos', 'igor.santos@skillbridge.com', 'Javascript, Node.js, React, APIs', '11988880009', 'Fortaleza', 'CE', 'Criar plataformas de talentos com IA generativa'),
      t_usuario_seed('Julia Oliveira', 'julia.oliveira@skillbridge.com', 'Machine Learning, Python, NLP', '11988880010', 'Salvador', 'BA', 'Construir modelos de recomendacao de carreira')
    );

    TYPE t_vaga_seed IS RECORD (
      titulo              VARCHAR2(150),
      empresa             VARCHAR2(120),
      requisitos          VARCHAR2(500),
      salario             NUMBER,
      tipo_contrato       VARCHAR2(30),
      localidade          VARCHAR2(100),
      formato             VARCHAR2(30),
      nivel               VARCHAR2(30),
      responsabilidades   VARCHAR2(500)
    );
    TYPE t_vaga_tab IS TABLE OF t_vaga_seed;
    v_vagas t_vaga_tab := t_vaga_tab(
      t_vaga_seed('Arquiteto(a) de Solucoes IA', 'TechLabs', 'Java, Microservices, Cloud, AI APIs', 14500, 'CLT', 'Sao Paulo/SP', 'HIBRIDO', 'Senior', 'Desenhar solucoes de IA corporativa'),
      t_vaga_seed('Cientista de Dados People Analytics', 'FutureCorp', 'Python, SQL, Power BI, Machine Learning', 13500, 'CLT', 'Campinas/SP', 'REMOTO', 'Pleno', 'Gerar insights para estrategia de talentos'),
      t_vaga_seed('Product Designer IA', 'VisionX', 'UX, UI, Figma, Design Thinking', 9800, 'PJ', 'Rio de Janeiro/RJ', 'HIBRIDO', 'Pleno', 'Projetar experiencias para produtos de IA'),
      t_vaga_seed('Scrum Master Requalificacao', 'GrowUp', 'Scrum, Kanban, OKRs, Facilitacao', 11000, 'CLT', 'Belo Horizonte/MG', 'HIBRIDO', 'Pleno', 'Conduzir squads de requalificacao'),
      t_vaga_seed('Engenheiro(a) DevOps Cloud', 'SkyOps', 'Kubernetes, Terraform, AWS, Observability', 15000, 'PJ', 'Curitiba/PR', 'REMOTO', 'Senior', 'Manter pipelines para plataformas de IA'),
      t_vaga_seed('Especialista em Ciberseguranca', 'SecureNow', 'Zero Trust, Redes, DevSecOps', 14000, 'CLT', 'Recife/PE', 'REMOTO', 'Senior', 'Garantir seguranca de ambientes distribuidos'),
      t_vaga_seed('Analista de Automacao RPA', 'AutoFlow', 'RPA, Python, BPM, Process Mining', 9200, 'CLT', 'Porto Alegre/RS', 'PRESENCIAL', 'Pleno', 'Automatizar fluxos de talentos'),
      t_vaga_seed('Analista de People Analytics', 'Insight Analytics', 'SQL, Python, Storytelling, Estatistica', 10500, 'CLT', 'Sao Paulo/SP', 'HIBRIDO', 'Pleno', 'Desenvolver dashboards de talentos'),
      t_vaga_seed('Desenvolvedor(a) Fullstack IA', 'NeuralApps', 'Node.js, React, APIs, Cloud Functions', 12500, 'PJ', 'Fortaleza/CE', 'REMOTO', 'Pleno', 'Construir plataforma SkillBridge'),
      t_vaga_seed('Engenheiro(a) de Machine Learning', 'TalentAI', 'Python, NLP, MLOps, Spark', 15500, 'CLT', 'Salvador/BA', 'REMOTO', 'Senior', 'Criar modelos de recomendacao de carreiras')
    );

    TYPE t_usuario_curso_seed IS RECORD (
      email       VARCHAR2(150),
      curso_nome  VARCHAR2(120),
      progresso   NUMBER
    );
    TYPE t_usuario_curso_tab IS TABLE OF t_usuario_curso_seed;
    v_usuario_curso t_usuario_curso_tab := t_usuario_curso_tab(
      t_usuario_curso_seed('afonso.pereira@skillbridge.com', 'Cloud Computing para Desenvolvedores', 45),
      t_usuario_curso_seed('bianca.rodrigues@skillbridge.com', 'Machine Learning para RH', 55),
      t_usuario_curso_seed('carlos.lima@skillbridge.com', 'UX para Produtos de IA', 70),
      t_usuario_curso_seed('daniela.martins@skillbridge.com', 'Gestao Agile de Carreiras', 65),
      t_usuario_curso_seed('emanuel.souza@skillbridge.com', 'Data Engineering com Spark', 40),
      t_usuario_curso_seed('fernanda.alves@skillbridge.com', 'Ciberseguranca para Empresas Hibridas', 80),
      t_usuario_curso_seed('gustavo.ferreira@skillbridge.com', 'Automacao com RPA', 90),
      t_usuario_curso_seed('helena.moraes@skillbridge.com', 'Analytics para Gestores de Talentos', 60),
      t_usuario_curso_seed('igor.santos@skillbridge.com', 'Imersao em Inteligencia Artificial', 35),
      t_usuario_curso_seed('julia.oliveira@skillbridge.com', 'Machine Learning para RH', 20),
      t_usuario_curso_seed('afonso.pereira@skillbridge.com', 'Data Engineering com Spark', 25),
      t_usuario_curso_seed('bianca.rodrigues@skillbridge.com', 'Analytics para Gestores de Talentos', 80)
    );

    TYPE t_aplicacao_seed IS RECORD (
      email       VARCHAR2(150),
      titulo      VARCHAR2(150),
      status      VARCHAR2(30),
      comentario  VARCHAR2(400)
    );
    TYPE t_aplicacao_tab IS TABLE OF t_aplicacao_seed;
    v_aplicacoes t_aplicacao_tab := t_aplicacao_tab(
      t_aplicacao_seed('afonso.pereira@skillbridge.com', 'Arquiteto(a) de Solucoes IA', 'EM_ANALISE', 'Perfil alinhado a arquitetura distribuida'),
      t_aplicacao_seed('bianca.rodrigues@skillbridge.com', 'Cientista de Dados People Analytics', 'ENTREVISTA', 'Convidada para desafio tecnico'),
      t_aplicacao_seed('carlos.lima@skillbridge.com', 'Product Designer IA', 'APROVADO', 'Portfolio forte em projetos de IA'),
      t_aplicacao_seed('daniela.martins@skillbridge.com', 'Scrum Master Requalificacao', 'EM_ANALISE', 'Aguardando retorno do product owner'),
      t_aplicacao_seed('emanuel.souza@skillbridge.com', 'Engenheiro(a) DevOps Cloud', 'ENTREVISTA', 'Sera avaliado pelo time de SRE'),
      t_aplicacao_seed('fernanda.alves@skillbridge.com', 'Especialista em Ciberseguranca', 'CONTRATADO', 'Oferta aceita para lideranca de seguranca'),
      t_aplicacao_seed('gustavo.ferreira@skillbridge.com', 'Analista de Automacao RPA', 'EM_ANALISE', 'Proposta de automatizacao entregue'),
      t_aplicacao_seed('helena.moraes@skillbridge.com', 'Analista de People Analytics', 'ENTREVISTA', 'Painel de storytelling marcado'),
      t_aplicacao_seed('igor.santos@skillbridge.com', 'Desenvolvedor(a) Fullstack IA', 'REPROVADO', 'Faltou experiencia com IA generativa'),
      t_aplicacao_seed('julia.oliveira@skillbridge.com', 'Engenheiro(a) de Machine Learning', 'EM_ANALISE', 'Aguardando resultado do case'),
      t_aplicacao_seed('afonso.pereira@skillbridge.com', 'Engenheiro(a) DevOps Cloud', 'ENTREVISTA', 'Perfil alternativo para vaga de SRE'),
      t_aplicacao_seed('helena.moraes@skillbridge.com', 'Cientista de Dados People Analytics', 'EM_ANALISE', 'Boa experiencia em analytics aplicado a RH')
    );

    TYPE t_id_map IS TABLE OF RAW(16) INDEX BY VARCHAR2(200);
    v_curso_ids    t_id_map;
    v_usuario_ids  t_id_map;
    v_vaga_ids     t_id_map;

    v_exist NUMBER;
    v_id    RAW(16);
  BEGIN
    -- Cursos
    FOR i IN 1 .. v_cursos.COUNT LOOP
      SELECT COUNT(*) INTO v_exist FROM curso WHERE LOWER(nome) = LOWER(v_cursos(i).nome);
      IF v_exist = 0 THEN
        INSERT INTO curso (nome, area, duracao_horas, modalidade, instituicao, descricao, nivel)
        VALUES (v_cursos(i).nome, v_cursos(i).area, v_cursos(i).duracao, v_cursos(i).modalidade,
                v_cursos(i).instituicao, v_cursos(i).descricao, v_cursos(i).nivel);
      END IF;
      SELECT id INTO v_id FROM curso WHERE LOWER(nome) = LOWER(v_cursos(i).nome);
      v_curso_ids(LOWER(v_cursos(i).nome)) := v_id;
    END LOOP;

    -- Usuarios
    FOR i IN 1 .. v_usuarios.COUNT LOOP
      SELECT COUNT(*) INTO v_exist FROM usuario WHERE LOWER(email) = LOWER(v_usuarios(i).email);
      IF v_exist = 0 THEN
        inserir_usuario(
          v_usuarios(i).nome,
          v_usuarios(i).email,
          v_usuarios(i).competencias,
          v_usuarios(i).telefone,
          v_usuarios(i).cidade,
          v_usuarios(i).uf,
          v_usuarios(i).objetivo
        );
      END IF;
      SELECT id INTO v_id FROM usuario WHERE LOWER(email) = LOWER(v_usuarios(i).email);
      v_usuario_ids(LOWER(v_usuarios(i).email)) := v_id;
    END LOOP;

    -- Vagas
    FOR i IN 1 .. v_vagas.COUNT LOOP
      SELECT COUNT(*) INTO v_exist FROM vaga WHERE LOWER(titulo) = LOWER(v_vagas(i).titulo);
      IF v_exist = 0 THEN
        pkg_vagas.inserir_vaga(
          v_vagas(i).titulo,
          v_vagas(i).empresa,
          v_vagas(i).requisitos,
          v_vagas(i).salario,
          v_vagas(i).tipo_contrato,
          v_vagas(i).localidade,
          v_vagas(i).formato,
          v_vagas(i).nivel,
          v_vagas(i).responsabilidades
        );
      END IF;
      SELECT id INTO v_id FROM vaga WHERE LOWER(titulo) = LOWER(v_vagas(i).titulo);
      v_vaga_ids(LOWER(v_vagas(i).titulo)) := v_id;
    END LOOP;

    -- Usuario x Curso
    FOR i IN 1 .. v_usuario_curso.COUNT LOOP
      IF v_usuario_ids.EXISTS(LOWER(v_usuario_curso(i).email)) AND
         v_curso_ids.EXISTS(LOWER(v_usuario_curso(i).curso_nome)) THEN
        BEGIN
          associar_usuario_curso(
            v_usuario_ids(LOWER(v_usuario_curso(i).email)),
            v_curso_ids(LOWER(v_usuario_curso(i).curso_nome))
          );
        EXCEPTION
          WHEN OTHERS THEN
            IF SQLCODE NOT IN (-20021) THEN
              RAISE;
            END IF;
        END;

        UPDATE usuario_curso
           SET progresso = v_usuario_curso(i).progresso
         WHERE usuario_id = v_usuario_ids(LOWER(v_usuario_curso(i).email))
           AND curso_id   = v_curso_ids(LOWER(v_usuario_curso(i).curso_nome));
      END IF;
    END LOOP;

    -- Aplicacoes
    FOR i IN 1 .. v_aplicacoes.COUNT LOOP
      IF v_usuario_ids.EXISTS(LOWER(v_aplicacoes(i).email)) AND
         v_vaga_ids.EXISTS(LOWER(v_aplicacoes(i).titulo)) THEN
        BEGIN
          pkg_vagas.registrar_aplicacao(
            v_usuario_ids(LOWER(v_aplicacoes(i).email)),
            v_vaga_ids(LOWER(v_aplicacoes(i).titulo)),
            v_aplicacoes(i).status
          );
        EXCEPTION
          WHEN OTHERS THEN
            IF SQLCODE NOT IN (-20033) THEN
              RAISE;
            END IF;
        END;

        UPDATE aplicacao
           SET comentarios_avaliador = v_aplicacoes(i).comentario
         WHERE usuario_id = v_usuario_ids(LOWER(v_aplicacoes(i).email))
           AND vaga_id    = v_vaga_ids(LOWER(v_aplicacoes(i).titulo));
      END IF;
    END LOOP;
  END popular_dados_iniciais;

  PROCEDURE associar_usuario_curso(
    p_usuario_id    RAW,
    p_curso_id      RAW
  ) AS
  BEGIN
    INSERT INTO usuario_curso (usuario_id, curso_id)
    VALUES (p_usuario_id, p_curso_id);
  EXCEPTION
    WHEN dup_val_on_index THEN
      RAISE_APPLICATION_ERROR(-20021, 'O usuario ja esta associado ao curso informado.');
    WHEN fk_violation THEN
      RAISE_APPLICATION_ERROR(-20022, 'Usuario ou curso inexistente.');
  END associar_usuario_curso;

  FUNCTION obter_json_usuario(p_usuario_id RAW) RETURN CLOB AS
    v_resultado CLOB;
  BEGIN
    SELECT '{' ||
           '"id":"' || RAWTOHEX(u.id) || '",' ||
           '"nome":"' || u.nome || '",' ||
           '"email":"' || u.email || '",' ||
           '"competencias":"' || NVL(u.competencias, '') || '",' ||
           '"cursos":[' ||
           LISTAGG(
             '{"curso":"' || c.nome || '","progresso":' || NVL(TO_CHAR(uc.progresso,'FM990D00'), '0') || '}',
             ','
           ) WITHIN GROUP (ORDER BY c.nome) ||
           ']' ||
           '}' INTO v_resultado
    FROM usuario u
    LEFT JOIN usuario_curso uc ON uc.usuario_id = u.id
    LEFT JOIN curso c ON c.id = uc.curso_id
    WHERE u.id = p_usuario_id
    GROUP BY u.id, u.nome, u.email, u.competencias;

    RETURN REPLACE(v_resultado, '[]','[]');
  EXCEPTION
    WHEN no_data_found THEN
      RAISE_APPLICATION_ERROR(-20023, 'Usuario nao encontrado.');
  END obter_json_usuario;
END pkg_usuarios;
/

COMMIT;


