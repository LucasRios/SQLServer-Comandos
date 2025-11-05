-- Exibe as 10 sessões mais ativas do SQL Server com base no uso de CPU.
SELECT TOP 10 
    s.session_id,                        -- Identificador da sessão (SPID)
    r.status,                            -- Status atual da requisição (running, suspended, etc.)
    r.cpu_time,                          -- Tempo total de CPU consumido pela requisição (em milissegundos)
    r.logical_reads,                     -- Quantidade de leituras lógicas realizadas (páginas lidas do buffer cache)
    r.reads,                             -- Leituras físicas feitas em disco
    r.writes,                            -- Escritas físicas em disco
    r.total_elapsed_time / (1000 * 60) AS 'Elaps M',  -- Tempo total de execução em minutos (converte de microssegundos)

    -- Recupera o texto exato da instrução SQL em execução.
    -- Usa offsets para pegar apenas o trecho da query que está sendo processado.
    SUBSTRING(
        st.TEXT,
        (r.statement_start_offset / 2) + 1,
        (
            (
                CASE r.statement_end_offset
                    WHEN -1 THEN DATALENGTH(st.TEXT)    -- Se o fim for -1, pega o texto completo
                    ELSE r.statement_end_offset
                END - r.statement_start_offset
            ) / 2
        ) + 1
    ) AS statement_text,

    -- Monta o nome completo do objeto (Database.Schema.Object) caso a instrução esteja associada a um objeto.
    COALESCE(
        QUOTENAME(DB_NAME(st.dbid)) + N'.' +
        QUOTENAME(OBJECT_SCHEMA_NAME(st.objectid, st.dbid)) + N'.' +
        QUOTENAME(OBJECT_NAME(st.objectid, st.dbid)),
        ''
    ) AS command_text,

    r.command,                           -- Tipo de comando em execução (SELECT, INSERT, etc.)
    s.login_name,                        -- Nome do usuário autenticado
    s.host_name,                         -- Nome do host (máquina cliente)
    s.program_name,                      -- Nome do aplicativo que iniciou a sessão (ex: SSMS, App .NET, etc.)
    s.last_request_end_time,             -- Hora em que a última requisição foi concluída
    s.login_time,                        -- Hora em que a sessão foi iniciada
    r.open_transaction_count             -- Número de transações abertas pela sessão

-- Tabelas de DMV usadas:
-- sys.dm_exec_sessions → informações de todas as sessões ativas/conectadas
-- sys.dm_exec_requests → informações de requisições em execução
-- sys.dm_exec_sql_text(sql_handle) → texto SQL associado ao handle da requisição
FROM sys.dm_exec_sessions AS s
JOIN sys.dm_exec_requests AS r
    ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st

-- Exclui a própria sessão (para não exibir o SPID atual do usuário que está rodando a consulta)
WHERE r.session_id != @@SPID

-- Ordena pelo tempo de CPU decrescente (mostra as requisições mais pesadas primeiro)
ORDER BY r.cpu_time DESC;
