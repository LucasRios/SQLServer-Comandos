-- Exibe recomendações de índices ausentes (missing indexes) no SQL Server,
-- calculando o ganho estimado e gerando o comando CREATE INDEX correspondente.

SELECT 
    -- Data/hora atual no formato ISO (yyyy-mm-ddThh:mm:ss)
    CONVERT(VARCHAR(30), GETDATE(), 126) AS runtime,

    -- Identificadores de grupo e índice dentro das DMV de índices ausentes
    mig.index_group_handle,
    mid.index_handle,

    -- Métrica de "melhoria estimada" calculada pelo otimizador de consultas
    -- Fórmula: custo_total_médio * impacto_médio * (buscas + scans)
    -- Quanto maior, mais crítico é o índice ausente.
    CONVERT(DECIMAL(28, 1),
        migs.avg_total_user_cost *
        migs.avg_user_impact *
        (migs.user_seeks + migs.user_scans)
    ) AS improvement_measure,

    -- Gera dinamicamente o comando CREATE INDEX sugerido pelo SQL Server
    'CREATE INDEX missing_index_' +
        CONVERT(VARCHAR, mig.index_group_handle) + '_' +
        CONVERT(VARCHAR, mid.index_handle) +
        ' ON ' + mid.statement + ' (' +
        ISNULL(mid.equality_columns, '') +
        CASE 
            WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ','
            ELSE ''
        END +
        ISNULL(mid.inequality_columns, '') + ')' +
        ISNULL(' INCLUDE (' + mid.included_columns + ')', '')
        AS create_index_statement,

    -- Exibe todas as colunas da DMV sys.dm_db_missing_index_group_stats
    migs.*,

    -- Identificação do banco e do objeto (tabela ou view)
    mid.database_id,
    mid.[object_id]

-- DMV principal: grupos de índices ausentes
FROM sys.dm_db_missing_index_groups AS mig

-- Junta com estatísticas acumuladas dos grupos (uso e impacto)
INNER JOIN sys.dm_db_missing_index_group_stats AS migs
    ON migs.group_handle = mig.index_group_handle

-- Junta com detalhes de cada índice ausente (colunas, tabelas)
INNER JOIN sys.dm_db_missing_index_details AS mid
    ON mig.index_handle = mid.index_handle

-- Filtro: ignora índices de baixo impacto
-- (só mostra sugestões com pontuação de melhoria > 10)
WHERE CONVERT(DECIMAL(28, 1),
        migs.avg_total_user_cost *
        migs.avg_user_impact *
        (migs.user_seeks + migs.user_scans)
    ) > 10

-- Ordena da maior para a menor melhoria estimada (mais importante primeiro)
ORDER BY
    migs.avg_total_user_cost *
    migs.avg_user_impact *
    (migs.user_seeks + migs.user_scans) DESC;
