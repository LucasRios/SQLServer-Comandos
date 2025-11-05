-- Retorna as 100 consultas mais recentes com base no tempo médio de CPU.
SELECT TOP 100  
    query_stats.creation_time,                -- Momento em que o plano de execução foi criado no cache
    query_stats.query_hash AS "Query Hash",   -- Identificador hash da consulta (mesmo para consultas com o mesmo texto base)
    
    -- Tempo médio de CPU por execução (total_worker_time dividido pelo número de execuções)
    SUM(query_stats.total_worker_time) / SUM(query_stats.execution_count) AS "Avg CPU Time",

    -- Texto da instrução SQL associada ao hash
    MIN(query_stats.statement_text) AS "Statement Text",

    -- Nome do banco de dados ao qual a consulta pertence
    db_name(query_stats.dbid) AS 'db_name'
FROM   
    (
        -- Subconsulta que associa as estatísticas de execução ao texto SQL original
        SELECT 
            QS.*,   
            -- Extrai o trecho da instrução em execução (parcial de texto SQL)
            SUBSTRING(
                ST.text,
                (QS.statement_start_offset / 2) + 1,
                (
                    (CASE statement_end_offset
                        WHEN -1 THEN DATALENGTH(ST.text)
                        ELSE QS.statement_end_offset
                    END - QS.statement_start_offset) / 2
                ) + 1
            ) AS statement_text, 
            ST.dbid
        FROM sys.dm_exec_query_stats AS QS
        CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) AS ST  -- Liga cada plano ao SQL correspondente
    ) AS query_stats

-- Agrupa por hash da consulta (query_hash = consultas idênticas independentemente dos parâmetros)
GROUP BY 
    query_stats.creation_time,
    query_stats.query_hash,
    query_stats.dbid

-- Ordena por data de criação do plano (mais recente primeiro) e tempo médio de CPU (mais custoso primeiro)
ORDER BY 1 DESC, 3 DESC;


-- Mostra progresso e detalhes de operadores de execução em consultas atualmente em execução.
SELECT  
    MAX(elapsed_time_ms),             -- Maior tempo decorrido entre os operadores
    session_id,                       -- SPID da sessão em execução
    node_id,                          -- Identificador do nó (etapa) dentro do plano de execução
    physical_operator_name,           -- Nome do operador físico (ex: Index Scan, Hash Match, Sort)
    
    SUM(row_count) AS row_count,      -- Quantidade total de linhas processadas até o momento
    SUM(estimate_row_count) AS estimate_row_count, -- Total estimado de linhas a processar
    
    -- Número de threads paralelas utilizadas (1 se não houver paralelismo)
    IIF(COUNT(thread_id) = 0, 1, COUNT(thread_id)) AS [Threads],

    -- Percentual de conclusão (linhas processadas / linhas estimadas)
    CAST(SUM(row_count) * 100. / SUM(estimate_row_count) AS DECIMAL(30, 2)) AS [% Complete],

    -- Tempo decorrido total convertido em formato TIME legível
    CONVERT(TIME, DATEADD(ms, MAX(elapsed_time_ms), 0)) AS [Operator time],

    -- Monta o nome completo do objeto afetado (Database.Schema.Table)
    DB_NAME(database_id) + '.' +
    OBJECT_SCHEMA_NAME(QP.object_id, qp.database_id) + '.' +
    OBJECT_NAME(QP.object_id, qp.database_id) AS [Object Name]

FROM sys.dm_exec_query_profiles AS QP  -- DMV que mostra métricas em tempo real da execução atual

GROUP BY 
    session_id,
    node_id,
    physical_operator_name,
    qp.database_id,
    QP.object_id,
    QP.index_id

ORDER BY 
    session_id,
    node_id;


