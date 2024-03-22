-- Criação da tabela temporária com os acessórios e acessórios obrigatórios
CREATE PROCEDURE [dbo].[marge3]
AS
BEGIN
    WITH Append1 AS (
        SELECT DISTINCT
            gg.corte,
            go.acessorio_obrigatorio AS acessorio
        FROM
            gab_gabacsg gg
            INNER JOIN gab_obracsg go ON gg.acessorio = go.acessorio
        UNION ALL
        SELECT
            corte,
            acessorio
        FROM
            gab_gabacsg
    )
    SELECT DISTINCT
        REPLACE(REPLACE(REPLACE(ga.chave_busca,'<MODELO>',a1.corte),'<COMPR>',gpmc.medida),'<ANGULO>',gpmc.tipo_med) AS chave_busca
    FROM
        Append1 a1
        INNER JOIN GAB_PARAM_MED_CRT gpmc ON a1.corte = gpmc.Corte
        INNER JOIN GAB_ACSG ga ON a1.acessorio = ga.acessorio;
END;
GO

-- Criação da função para dividir uma string em várias partes usando um delimitador
CREATE FUNCTION [dbo].[Split3]
(
    @String NVARCHAR(4000),
    @Delimiter NCHAR(1)
)
RETURNS TABLE
AS
RETURN
(
    WITH Split(stpos, endpos) AS (
        SELECT
            0 AS stpos,
            CHARINDEX(@Delimiter, @String) AS endpos
        UNION ALL
        SELECT
            endpos + 1,
            CHARINDEX(@Delimiter, @String, endpos + 1)
        FROM
            Split
        WHERE
            endpos > 0
    )
    SELECT
        'Id' = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
        'Data' = SUBSTRING(@String, stpos, COALESCE(NULLIF(endpos, 0), LEN(@String) + 1) - stpos)
    FROM
        Split
);

-- Criação das tabelas e população de dados para PAR1 a PAR12 (exemplo para PAR1)
CREATE PROCEDURE [dbo].[PopulateParams]
AS
BEGIN
    DECLARE @ParamName NVARCHAR(128);
    DECLARE @ParamCode NVARCHAR(10);

    -- Loop para popular as tabelas com os parâmetros
    DECLARE ParamCursor CURSOR FOR
    SELECT
        lista,
        codigochave
    FROM
        tblDados_projeto
    WHERE
        grupo LIKE 'não usar';

    OPEN ParamCursor;
    FETCH NEXT FROM ParamCursor INTO @ParamName, @ParamCode;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @DelimitedString NVARCHAR(128);
        SET @DelimitedString = (SELECT DISTINCT lista FROM tblDados_projeto WHERE codigochave = @ParamCode);

        CREATE TABLE #ParamTable (
            [Value] VARCHAR(128)
        );

        INSERT INTO #ParamTable
        SELECT
            data
        FROM
            dbo.Split3(@DelimitedString, '|');

        FETCH NEXT FROM ParamCursor INTO @ParamName, @ParamCode;
    END;

    CLOSE ParamCursor;
    DEALLOCATE ParamCursor;
END;
GO

-- Criação das tabelas temporárias para armazenar os resultados
CREATE TABLE #marge3 (
    chave_busca VARCHAR(100)
);

CREATE TABLE #chave_busca_teste1 (
    chave_busca VARCHAR(100)
);

CREATE TABLE #chave_busca_final (
    chave_busca VARCHAR(100)
);

-- Execução do procedimento e população dos dados
EXEC marge3;

-- População dos dados para PAR1
EXEC PopulateParams;

-- Limpando as tabelas temporárias
DROP TABLE #marge3;
DROP TABLE #chave_busca_teste1;
DROP TABLE #chave_busca_final;
