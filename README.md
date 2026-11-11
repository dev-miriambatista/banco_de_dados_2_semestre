# Banco de Dados II — Atividades do 2º Bimestre

Scripts SQL (MySQL 8+) das atividades de Banco de Dados II, curso de Análise e Desenvolvimento de Sistemas, Faculdade Senac PR.

## Estrutura

```
banco-de-dados-ii/
├── sql-quest/
│   ├── 01_setup_sql_quest.sql      # criação e carga da tabela jogadores
│   └── 02_recuperacao.sql          # etapas 1 a 7 + auditoria final
└── techmarket-views/
    ├── 01_setup_techmarket.sql     # criação e carga do db_techmarket
    └── 02_views_techmarket.sql     # views, relatórios, manutenção e respostas técnicas
```

## Como executar

1. Rode o script de setup da atividade (`01_...`) no MySQL.
2. Rode o script da atividade (`02_...`) na ordem em que estão escritos.

Na SQL Quest, a ordem das etapas importa: cada uma altera o estado da tabela que a seguinte usa. Não execute as etapas isoladamente.

## Observações

- O `02_recuperacao.sql` desativa `SQL_SAFE_UPDATES` temporariamente, porque o MySQL Workbench bloqueia UPDATE e DELETE sem chave.
- Subconsultas que leem da mesma tabela que está sendo alterada são envolvidas em tabela derivada, para evitar o erro 1093 do MySQL.
- Enunciados, slides e PDFs da disciplina não fazem parte deste repositório.
