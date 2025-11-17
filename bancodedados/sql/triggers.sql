-------------------------------------------------------------------------------
-- Global Solution 2025/2 - SkillBridge Database (Oracle)
-- Auditoria via triggers
-------------------------------------------------------------------------------
SET DEFINE OFF;

-------------------------------------------------------------------------------
-- Trigger: USUARIO
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_auditoria_usuario
AFTER INSERT OR UPDATE OR DELETE ON usuario
FOR EACH ROW
DECLARE
  v_acao       VARCHAR2(20);
  v_descricao  VARCHAR2(400);
BEGIN
  IF INSERTING THEN
    v_acao := 'INSERT';
    v_descricao := 'Usuario criado: ' || :NEW.email;
  ELSIF UPDATING THEN
    v_acao := 'UPDATE';
    v_descricao := 'Usuario atualizado: ' || NVL(:NEW.email, :OLD.email);
  ELSE
    v_acao := 'DELETE';
    v_descricao := 'Usuario removido: ' || :OLD.email;
  END IF;

  pkg_auditoria.registrar_evento('USUARIO', v_acao, v_descricao);
END;
/

-------------------------------------------------------------------------------
-- Trigger: VAGA
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_auditoria_vaga
AFTER INSERT OR UPDATE OR DELETE ON vaga
FOR EACH ROW
DECLARE
  v_acao       VARCHAR2(20);
  v_descricao  VARCHAR2(400);
BEGIN
  IF INSERTING THEN
    v_acao := 'INSERT';
    v_descricao := 'Vaga criada: ' || :NEW.titulo;
  ELSIF UPDATING THEN
    v_acao := 'UPDATE';
    v_descricao := 'Vaga atualizada: ' || NVL(:NEW.titulo, :OLD.titulo);
  ELSE
    v_acao := 'DELETE';
    v_descricao := 'Vaga removida: ' || :OLD.titulo;
  END IF;

  pkg_auditoria.registrar_evento('VAGA', v_acao, v_descricao);
END;
/

-------------------------------------------------------------------------------
-- Trigger: CURSO
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_auditoria_curso
AFTER INSERT OR UPDATE OR DELETE ON curso
FOR EACH ROW
DECLARE
  v_acao       VARCHAR2(20);
  v_descricao  VARCHAR2(400);
BEGIN
  IF INSERTING THEN
    v_acao := 'INSERT';
    v_descricao := 'Curso criado: ' || :NEW.nome;
  ELSIF UPDATING THEN
    v_acao := 'UPDATE';
    v_descricao := 'Curso atualizado: ' || NVL(:NEW.nome, :OLD.nome);
  ELSE
    v_acao := 'DELETE';
    v_descricao := 'Curso removido: ' || :OLD.nome;
  END IF;

  pkg_auditoria.registrar_evento('CURSO', v_acao, v_descricao);
END;
/

-------------------------------------------------------------------------------
-- Trigger: APLICACAO
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_auditoria_aplicacao
AFTER INSERT OR UPDATE OR DELETE ON aplicacao
FOR EACH ROW
DECLARE
  v_acao       VARCHAR2(20);
  v_descricao  VARCHAR2(400);
BEGIN
  IF INSERTING THEN
    v_acao := 'INSERT';
    v_descricao := 'Aplicacao criada para vaga ' || RAWTOHEX(:NEW.vaga_id);
  ELSIF UPDATING THEN
    v_acao := 'UPDATE';
    v_descricao := 'Aplicacao atualizada para vaga ' || RAWTOHEX(NVL(:NEW.vaga_id, :OLD.vaga_id));
  ELSE
    v_acao := 'DELETE';
    v_descricao := 'Aplicacao removida para vaga ' || RAWTOHEX(:OLD.vaga_id);
  END IF;

  pkg_auditoria.registrar_evento('APLICACAO', v_acao, v_descricao);
END;
/

-------------------------------------------------------------------------------
-- Trigger: USUARIO_CURSO (extra auditoria opcional)
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_auditoria_usuario_curso
AFTER INSERT OR UPDATE OR DELETE ON usuario_curso
FOR EACH ROW
DECLARE
  v_acao       VARCHAR2(20);
  v_descricao  VARCHAR2(400);
BEGIN
  IF INSERTING THEN
    v_acao := 'INSERT';
    v_descricao := 'Usuario inscrito no curso ' || RAWTOHEX(:NEW.curso_id);
  ELSIF UPDATING THEN
    v_acao := 'UPDATE';
    v_descricao := 'Progresso atualizado para curso ' || RAWTOHEX(NVL(:NEW.curso_id, :OLD.curso_id));
  ELSE
    v_acao := 'DELETE';
    v_descricao := 'Usuario removido do curso ' || RAWTOHEX(:OLD.curso_id);
  END IF;

  pkg_auditoria.registrar_evento('USUARIO_CURSO', v_acao, v_descricao);
END;
/

COMMIT;


