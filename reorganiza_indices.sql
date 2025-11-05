-- Script para manutenção de índices não clusterizados (NONCLUSTERED)
-- Faz REBUILD e REORGANIZE em todos os índices não-clusterizados de todas as tabelas.

DECLARE @curCon CURSOR;              -- Cursor para iterar sobre os índices encontrados
DECLARE @SQLString VARCHAR(MAX);     -- Comando SQL dinâmico
DECLARE @Tabela VARCHAR(MAX);        -- Nome da tabela
DECLARE @Indice VARCHAR(MAX);        -- Nome do índice

-- Cria cursor com todos os índices não-clusterizados do banco atual
SET @curCon = CURSOR FOR
SELECT
    T.name AS Tabela,                -- Nome da tabela
    I.name AS Indice                 -- Nome do índice
FROM sys.indexes AS I
JOIN sys.tables AS T 
    ON T.object_id = I.object_id
JOIN sys.sysindexes AS SI 
    ON I.object_id = SI.id AND I.index_id = SI.indid
WHERE 
    I.type_desc = 'NONCLUSTERED'     -- Apenas índices não clusterizados (secundários)
ORDER BY 
    T.name, I.index_id;              -- Ordena por tabela e índice

-- Abre o cursor e pega o primeiro índice
OPEN @curCon;
FETCH NEXT FROM @curCon INTO @Tabela, @Indice;

-- Loop para percorrer todos os índices
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Monta dinamicamente os comandos ALTER INDEX
    SET @SQLString = '
        ALTER INDEX [' + @Indice + '] ON [dbo].[' + @Tabela + '] 
        REBUILD PARTITION = ALL 
        WITH (
            PAD_INDEX = OFF, 
            STATISTICS_NORECOMPUTE = OFF, 
            SORT_IN_TEMPDB = OFF, 
            ONLINE = OFF, 
            ALLOW_ROW_LOCKS = ON, 
            ALLOW_PAGE_LOCKS = ON
        );

        ALTER INDEX [' + @Indice + '] ON [dbo].[' + @Tabela + '] 
        REORGANIZE WITH (LOB_COMPACTION = ON);
    ';

    -- Bloco TRY/CATCH para evitar que falhas parem o script completo
    BEGIN TRY
        EXEC(@SQLString);  -- Executa o SQL dinâmico
    END TRY
    BEGIN CATCH
        -- Retorna mensagem de erro, caso algum índice falhe
        SELECT 'Erro no índice ' + @Tabela + ' - ' + @Indice;
    END CATCH;

    -- Move o cursor para o próximo índice
    FETCH NEXT FROM @curCon INTO @Tabela, @Indice;
END;

-- Fecha e desaloca o cursor
CLOSE @curCon;
DEALLOCATE @curCon;
