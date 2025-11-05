-- Seleciona o banco de sistema master para garantir acesso às DMV e traces
USE [master];
GO

BEGIN TRY
    -- Verifica se o recurso "default trace" está habilitado na instância
    -- sys.configurations: contém as configurações do servidor
    -- 'default trace enabled' = 1 significa que o SQL Server está gravando o trace padrão (log interno)
    IF (SELECT CONVERT(INT, value_in_use)
        FROM sys.configurations
        WHERE NAME = 'default trace enabled') = 1
    BEGIN
        -- Declara variáveis para armazenar o nome e caminho do arquivo de trace atual
        DECLARE @curr_tracefilename VARCHAR(500);
        DECLARE @base_tracefilename VARCHAR(500);
        DECLARE @indx INT;

        -- Busca o caminho completo do arquivo de trace padrão atual
        SELECT @curr_tracefilename = path FROM sys.traces WHERE is_default = 1;

        -- Reverte a string para facilitar a extração do nome base
        SET @curr_tracefilename = REVERSE(@curr_tracefilename);

        -- Encontra a posição do primeiro caractere "\" (usado como separador de diretórios)
        SELECT @indx = PATINDEX('%\%', @curr_tracefilename);

        -- Reverte novamente o caminho para a forma normal
        SET @curr_tracefilename = REVERSE(@curr_tracefilename);

        -- Remove a parte do arquivo (ex: log_123.trc) para montar o caminho base até a pasta "log"
        -- Exemplo: C:\Program Files\Microsoft SQL Server\MSSQL15\MSSQL\Log\log.trc
        SET @base_tracefilename = LEFT(@curr_tracefilename, LEN(@curr_tracefilename) - @indx) + '\log.trc'; 

        -- Consulta o conteúdo do arquivo de trace usando a função de tabela fn_trace_gettable()
        -- Essa função lê arquivos .trc e retorna eventos registrados (DDL, crescimento de arquivo, etc.)
        SELECT
            --ServerName identifica a instância SQL de origem do evento
            ServerName AS [SQL_Instance],

            --Nome do banco de dados onde ocorreu o evento
            DatabaseName AS [Database_Name],

            --Nome lógico do arquivo afetado (geralmente MDF, NDF ou LDF)
            Filename AS [Logical_File_Name],

            --Duração do evento (em milissegundos). O trace armazena em microssegundos → divide por 1000
            (Duration / 1000) AS [Duration_MS],

            --Momento de início do evento formatado
            CONVERT(VARCHAR(50), StartTime, 100) AS [Start_Time],

            --Quantidade de crescimento do arquivo (em MB)
            --IntegerData representa número de páginas de 8 KB → multiplica por 8 e converte para MB
            CAST((IntegerData * 8.0 / 1024) AS DECIMAL(19, 2)) AS [Change_In_Size_MB]
        FROM ::fn_trace_gettable(@base_tracefilename, DEFAULT)
        WHERE
            -- Filtro pelos tipos de evento de crescimento de arquivo
            -- EventClass 92 a 95 correspondem a:
            -- 92 = Data File Auto Grow
            -- 93 = Log File Auto Grow
            -- 94 = Data File Auto Shrink
            -- 95 = Log File Auto Shrink
            EventClass >= 92
            AND EventClass <= 95
            -- Pode-se filtrar por instância ou banco, se desejado:
            -- AND ServerName = @@SERVERNAME
            -- AND DatabaseName = 'myDBName'
        ORDER BY StartTime DESC;  -- Mostra os eventos mais recentes primeiro
    END    

    -- Caso o trace padrão esteja desativado
    ELSE
        SELECT -1 AS l1,
               0 AS EventClass,
               0 AS DatabaseName,
               0 AS Filename,
               0 AS Duration,
               0 AS StartTime,
               0 AS EndTime,
               0 AS ChangeInSize;
END TRY 

-- Captura exceções (erros na execução)
BEGIN CATCH 
    SELECT -100 AS l1,                            -- Indicador de erro
           ERROR_NUMBER() AS EventClass,          -- Número do erro
           ERROR_SEVERITY() AS DatabaseName,      -- Severidade (aqui renomeada para DatabaseName só por compatibilidade de colunas)
           ERROR_STATE() AS Filename,             -- Estado do erro
           ERROR_MESSAGE() AS Duration,           -- Mensagem de erro
           1 AS StartTime, 
           1 AS EndTime,
           1 AS ChangeInSize;                     -- Valores dummy para manter estrutura da query
END CATCH;
