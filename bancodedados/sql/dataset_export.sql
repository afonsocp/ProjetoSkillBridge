-------------------------------------------------------------------------------
-- Global Solution 2025/2 - SkillBridge Database (Oracle)
-- Procedure de exportacao de dataset para JSON via DBMS_OUTPUT
-------------------------------------------------------------------------------
SET DEFINE OFF;

CREATE OR REPLACE PROCEDURE exportar_dataset_json AS
  v_json     CLOB;
  v_posicao  PLS_INTEGER := 1;
  v_step     CONSTANT PLS_INTEGER := 25000;
  v_total    PLS_INTEGER;
BEGIN
  v_json := fn_gerar_json_manual();
  v_total := DBMS_LOB.GETLENGTH(v_json);

  WHILE v_posicao <= v_total LOOP
    DBMS_OUTPUT.PUT_LINE(SUBSTR(v_json, v_posicao, v_step));
    v_posicao := v_posicao + v_step;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erro ao exportar dataset: ' || SQLERRM);
END exportar_dataset_json;
/

COMMIT;


