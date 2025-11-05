# SQLServer-PerformanceToolkit 🚀

Coleção de **scripts T-SQL** voltados para **monitoramento, diagnóstico e otimização de desempenho no SQL Server**.  
Inclui consultas de análise de CPU, fragmentação, índices, espaço em disco e manutenção automática.

---

## 🧰 Funcionalidades Principais

- 🔍 **Monitoramento de Sessões Ativas**
  - Exibe consultas em execução, tempo de CPU, leituras e transações abertas.

- ⚙️ **Análise de Desempenho Histórico**
  - Identifica consultas mais pesadas por tempo médio de CPU e tempo total decorrido.

- 📈 **Sugestão de Índices Ausentes**
  - Retorna recomendações automáticas do otimizador com script `CREATE INDEX` pronto.

- 🧹 **Manutenção Automática de Índices**
  - Reorganiza ou reconstrói índices conforme o nível de fragmentação detectado.

- 💾 **Relatório de Uso de Espaço**
  - Lista as maiores tabelas do banco com espaço total, usado e não utilizado.

- 🧮 **Análise de Execuções em Tempo Real**
  - Monitora operadores de execução (`sys.dm_exec_query_profiles`) com percentual concluído.

---

 

## 🚀 Como Usar

1. **Abra o SQL Server Management Studio (SSMS)**  
2. **Execute o script desejado** diretamente no banco que deseja analisar  
3. Revise as recomendações ou resultados no painel de resultados  

💡 **Dica:**  
Os scripts não modificam dados, exceto os de **manutenção de índices**, que podem ser agendados como tarefas (SQL Agent Job) para execução periódica.

---

## 🧩 Requisitos

- SQL Server 2016 ou superior (recomendado)
- Permissão `VIEW SERVER STATE` e `VIEW DATABASE STATE`
- Acesso de administrador (para scripts de manutenção)

---

## ⚠️ Observações Importantes

- O uso de DMV (Dynamic Management Views) requer permissões elevadas.  
- Os scripts de manutenção (`REBUILD`, `REORGANIZE`) podem causar **bloqueios** em ambientes com alta carga.  
- Sempre execute primeiro em **ambientes de teste**.  
- `sys.dm_exec_query_profiles` só traz resultados **enquanto a consulta está sendo executada**.  

---

## 📚 Conceitos Envolvidos

- DMV (Dynamic Management Views): visões internas do SQL Server para diagnóstico.
- Fragmentação de índices: desalinhamento físico dos dados, prejudica performance.
- Query Hash: agrupa execuções semelhantes para análise consolidada.
- Execution Plan Profiles: informações em tempo real sobre execução de operadores.

## 🤝 Contribuição

Sinta-se livre para abrir PRs com novos scripts, melhorias de legibilidade ou novos relatórios.
 
## 📜 Licença

Distribuído sob licença MIT, livre para uso pessoal e profissional.
Ideal para DBAs, desenvolvedores e analistas de performance SQL Server.

Feito com 🧠, T-SQL e foco em performance.
