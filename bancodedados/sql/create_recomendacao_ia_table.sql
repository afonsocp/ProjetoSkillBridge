-------------------------------------------------------------------------------
-- Tabela para armazenar recomendações geradas pela IA (Gemini)
-- Global Solution 2025/2 - SkillBridge Database (Oracle)
-------------------------------------------------------------------------------

CREATE TABLE recomendacao_ia (
    id                  RAW(16)        DEFAULT SYS_GUID() PRIMARY KEY,
    usuario_id          RAW(16)        NOT NULL,
    resumo_perfil       CLOB,
    plano_carreira      CLOB,
    cursos_recomendados CLOB,          -- JSON array de cursos
    vagas_recomendadas  CLOB,          -- JSON array de vagas
    json_completo       CLOB,          -- JSON completo retornado pela IA
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

