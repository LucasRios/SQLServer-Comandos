-- Lista as 100 maiores tabelas do banco de dados por tamanho em MB,
-- incluindo espaço total, usado e não utilizado (fragmentação interna).

SELECT TOP 100
    s.[name] AS [schema],        -- Nome do schema (ex: dbo)
    t.[name] AS [table_name],    -- Nome da tabela
    p.[rows] AS [row_count],     -- Quantidade de linhas da tabela

    -- Tamanho total alocado em MB (total_pages * 8 KB / 1024 = MB)
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [size_mb],

    -- Espaço efetivamente usado em MB (used_pages)
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [used_mb],

    -- Espaço não utilizado em MB (total - usado)
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS [unused_mb]

FROM 
    sys.tables t                              -- Metadados de tabelas do banco
    JOIN sys.indexes i 
        ON t.[object_id] = i.[object_id]      -- Relaciona índices com as tabelas
    JOIN sys.partitions p 
        ON i.[object_id] = p.[object_id] 
        AND i.index_id = p.index_id           -- Liga partições a índices
    JOIN sys.allocation_units a 
        ON p.[partition_id] = a.container_id  -- Liga às unidades de alocação física
    LEFT JOIN sys.schemas s 
        ON t.[schema_id] = s.[schema_id]      -- Associa cada tabela ao seu schema

WHERE 
    t.is_ms_shipped = 0                       -- Ignora objetos internos do sistema
    AND i.[object_id] > 255                   -- Evita objetos de sistema antigos

GROUP BY
    t.[name], 
    s.[name], 
    p.[rows]                                 -- Agrupa por tabela e schema

ORDER BY 
    [size_mb] DESC;                           -- Mostra primeiro as maiores tabelas
