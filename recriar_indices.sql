-- Script de manutenção automática de índices fragmentados
-- Avalia índices no banco atual e reorganiza ou reconstrói conforme o nível de fragmentação

DECLARE @tableName NVARCHAR(500);          -- Nome da tabela
DECLARE @indexName NVARCHAR(500);          -- Nome do índice
DECLARE @percentFragment DECIMAL(11,2);    -- Percentual de fragmentação
DECLARE @page_count INT;                   -- Quantidade de páginas do índice

-- Criação do cursor que percorre os índices fragmentados
DECLARE FragmentedTableList CURSOR FOR
SELECT  
    dbtables.[name] AS 'Table',                   -- Nome da tabela
    dbindexes.[name] AS 'Index',                  -- Nome do índice
    indexstats.avg_fragmentation_in_percent,      -- Percentual de fragmentação do índice
    indexstats.page_count                         -- Quantidade de páginas do índice
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
    INNER JOIN sys.tables dbtables 
        ON dbtables.[object_id] = indexstats.[object_id]
    INNER JOIN sys.schemas dbschemas 
        ON dbtables.[schema_id] = dbschemas.[schema_id]
    INNER JOIN sys.indexes dbindexes 
        ON dbindexes.[object_id] = indexstats.[object_id]
        AND indexstats.index_id = dbindexes.index_id
        AND dbindexes.[name] IS NOT NULL
WHERE 
    indexstats.database_id = DB_ID()               -- Apenas o banco atual
    AND indexstats.avg_fragmentation_in_percent > 5 -- Fragmentação mínima de 5%
    AND indexstats.page_count > 10                 -- Evita índices muito pequenos
ORDER BY 
    indexstats.page_count DESC,                    -- Prioriza índices maiores
    indexstats.avg_fragmentation_in_percent DESC;  -- E mais fragmentados

-- Abre o cursor e lê o primeiro registro
OPEN FragmentedTableList;
FETCH NEXT FROM FragmentedTableList  
INTO @tableName, @indexName, @percentFragment, @page_count;

-- Loop principal que percorre todos os índices fragmentados
WHILE @@FETCH_STATUS = 0 
BEGIN 
    PRINT 'Processando ' + @indexName + ' na tabela ' + @tableName + 
          ' com ' + CAST(@percentFragment AS NVARCHAR(50)) + '% fragmentado';

    -- Se a fragmentação estiver entre 5% e 30%, faz REORGANIZE (menos intrusivo)
    IF (@percentFragment BETWEEN 5 AND 30) 
    BEGIN 
        EXEC('ALTER INDEX ' + @indexName + ' ON ' + @tableName + ' REORGANIZE;');
        PRINT 'Concluindo a reorganização do índice ' + @indexName + 
              ' da tabela ' + @tableName;
    END 
    -- Se a fragmentação for maior que 30%, faz REBUILD (recria o índice do zero)
    ELSE IF (@percentFragment > 30)
    BEGIN 
        EXEC('ALTER INDEX ' + @indexName + ' ON ' + @tableName + ' REBUILD;');
        PRINT 'Concluindo a recriação do índice ' + @indexName + 
              ' da tabela ' + @tableName;
    END  

    -- Avança para o próximo índice
    FETCH NEXT FROM FragmentedTableList  
    INTO @tableName, @indexName, @percentFragment, @page_count;
END 

-- Encerra e libera o cursor
CLOSE FragmentedTableList;
DEALLOCATE FragmentedTableList;
