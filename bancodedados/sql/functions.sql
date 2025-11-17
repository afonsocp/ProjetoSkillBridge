-------------------------------------------------------------------------------
-- Global Solution 2025/2 - SkillBridge Database (Oracle)
-- Custom Functions
-------------------------------------------------------------------------------
SET DEFINE OFF;

-------------------------------------------------------------------------------
-- Function: FN_GERAR_JSON_MANUAL
-- Gera JSON manualmente a partir da tabela USUARIO
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_gerar_json_manual RETURN CLOB IS
  v_resultado        CLOB := '{' || CHR(10) || '  "usuarios": [' || CHR(10);
  v_contador         PLS_INTEGER := 0;
  v_limite_buffer    CONSTANT PLS_INTEGER := 32000;
  ex_buffer_limite   EXCEPTION;
BEGIN
  FOR r IN (
    SELECT u.id,
           u.nome,
           u.email,
           NVL(u.competencias, '') competencias,
           NVL(u.cidade, '') cidade,
           NVL(u.uf, '') uf,
           NVL(TO_CHAR(u.data_cadastro, 'YYYY-MM-DD'), '') data_cadastro
      FROM usuario u
     ORDER BY u.data_cadastro
  ) LOOP
    IF v_contador > 0 THEN
      v_resultado := v_resultado || ',' || CHR(10);
    END IF;

    v_resultado := v_resultado ||
      '    {' || CHR(10) ||
      '      "id": "' || RAWTOHEX(r.id) || '",' || CHR(10) ||
      '      "nome": "' || REPLACE(r.nome, '"', '\"') || '",' || CHR(10) ||
      '      "email": "' || REPLACE(r.email, '"', '\"') || '",' || CHR(10) ||
      '      "competencias": "' || REPLACE(r.competencias, '"', '\"') || '",' || CHR(10) ||
      '      "cidade": "' || REPLACE(r.cidade, '"', '\"') || '",' || CHR(10) ||
      '      "uf": "' || REPLACE(r.uf, '"', '\"') || '",' || CHR(10) ||
      '      "dataCadastro": "' || r.data_cadastro || '"' || CHR(10) ||
      '    }';

    IF DBMS_LOB.GETLENGTH(v_resultado) > v_limite_buffer THEN
      RAISE ex_buffer_limite;
    END IF;

    v_contador := v_contador + 1;
  END LOOP;

  IF v_contador = 0 THEN
    RAISE NO_DATA_FOUND;
  END IF;

  v_resultado := v_resultado || CHR(10) || '  ]' || CHR(10) || '}';
  RETURN v_resultado;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Nenhum usuario encontrado.');
    RETURN '{' || CHR(10) || '  "erro": "nenhum dado encontrado"' || CHR(10) || '}';
  WHEN VALUE_ERROR THEN
    DBMS_OUTPUT.PUT_LINE('Erro de tipo nos dados.');
    RETURN '{' || CHR(10) || '  "erro": "falha na conversao de tipo"' || CHR(10) || '}';
  WHEN ex_buffer_limite THEN
    DBMS_OUTPUT.PUT_LINE('Tamanho do JSON excede o limite controlado pela funcao.');
    RETURN '{' || CHR(10) || '  "erro": "limite de buffer excedido"' || CHR(10) || '}';
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erro inesperado: ' || SQLERRM);
    RETURN '{' || CHR(10) || '  "erro": "falha inesperada"' || CHR(10) || '}';
END fn_gerar_json_manual;
/

-------------------------------------------------------------------------------
-- Function: FN_CALCULAR_COMPATIBILIDADE
-- Valida entradas e retorna JSON com percentual calculado
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_calcular_compatibilidade(
  competencias_usuario VARCHAR2,
  requisitos_vaga      VARCHAR2
) RETURN VARCHAR2 IS
  v_percentual NUMBER;
  v_requisitos_count NUMBER := 0;
  v_matches NUMBER := 0;
BEGIN
  IF competencias_usuario IS NULL OR requisitos_vaga IS NULL THEN
    RAISE_APPLICATION_ERROR(-20002, 'Competencias ou requisitos nao informados.');
  END IF;

  IF NOT REGEXP_LIKE(competencias_usuario, '^[A-Za-z, ]+$') THEN
    RAISE_APPLICATION_ERROR(-20003, 'Formato invalido para competencias.');
  END IF;

  FOR req IN (
    SELECT TRIM(REGEXP_SUBSTR(requisitos_vaga, '[^,]+', 1, LEVEL)) requisito
      FROM dual
    CONNECT BY REGEXP_SUBSTR(requisitos_vaga, '[^,]+', 1, LEVEL) IS NOT NULL
  ) LOOP
    v_requisitos_count := v_requisitos_count + 1;
    IF INSTR(LOWER(competencias_usuario), LOWER(req.requisito)) > 0 THEN
      v_matches := v_matches + 1;
    END IF;
  END LOOP;

  IF v_requisitos_count = 0 THEN
    v_percentual := 0;
  ELSE
    v_percentual := (v_matches / v_requisitos_count) * 100;
  END IF;

  RETURN '{"compatibilidade": ' || TO_CHAR(ROUND(LEAST(v_percentual, 100), 2), 'FM990D00') || '}';

EXCEPTION
  WHEN VALUE_ERROR THEN
    RETURN '{"erro": "falha ao calcular compatibilidade"}';
  WHEN OTHERS THEN
    RETURN '{"erro": "' || REPLACE(SQLERRM, '"', '''') || '"}';
END fn_calcular_compatibilidade;
/

COMMIT;


