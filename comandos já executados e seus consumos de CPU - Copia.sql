-- Exibe as 10 consultas mais custosas em média de CPU (histórico de execução em cache)
SELECT TOP 10  
    qs.last_execution_time,     -- Data e hora da última execução da consulta

    st.text AS batch_text,      -- Texto completo do batch SQL (pode conter várias instruções)

    -- Extrai apenas o trecho da instrução específica dentro do batch
    SUBSTRING(
        st.TEXT,
        (qs.statement_start_offset / 2) + 1,
        (
            (
                CASE qs.statement_end_offset
                    WHEN -1 THEN DATALENGTH(st.TEXT)  -- Quando -1, lê até o fim do texto
                    ELSE qs.statement_end_offset
                END - qs.statement_start_offset
            ) / 2
        ) + 1
    ) AS statement_text,

    -- Tempo médio de CPU gasto por execução (ms)
    (qs.total_worker_time / 1000) / qs.execution_count AS avg_cpu_time_ms,

    -- Tempo médio total decorrido (CPU + espera, em ms)
    (qs.total_elapsed_time / 1000) / qs.execution_count AS avg_elapsed_time_ms,

    -- Leituras lógicas médias por execução (páginas lidas do buffer cache)
    qs.total_logical_reads / qs.execution_count AS avg_logical_reads,

    -- Tempo total de CPU gasto por todas as execuções combinadas (ms)
    (qs.total_worker_time / 1000) AS cumulative_cpu_time_all_executions_ms,

    -- Tempo total decorrido em todas as execuções (ms)
    (qs.total_elapsed_time / 1000) AS cumulative_elapsed_time_all_executions_ms

-- DMV sys.dm_exec_query_stats: contém estatísticas agregadas de consultas executadas recentemente
FROM sys.dm_exec_query_stats qs

-- CROSS APPLY usado para associar o texto SQL de cada handle de consulta
CROSS APPLY sys.dm_exec_sql_text(sql_handle) st

-- Ordena pelas consultas que tiveram maior uso médio de CPU por execução
ORDER BY (qs.total_worker_time / qs.execution_count) DESC;
