USE db_techmarket;

-- Missão 1: visão consolidada das vendas
DROP VIEW IF EXISTS vw_vendas_detalhadas;
CREATE VIEW vw_vendas_detalhadas AS
SELECT
    p.id_pedido,
    p.data_pedido,
    c.id_cliente,
    c.nome AS cliente,
    c.cidade,
    c.estado,
    v.id_vendedor,
    v.nome AS vendedor,
    v.equipe,
    pr.id_produto,
    pr.descricao AS produto,
    pr.categoria,
    ip.quantidade,
    ip.preco_unitario,
    ip.desconto_percentual,
    ip.quantidade * ip.preco_unitario AS valor_bruto,
    ip.quantidade * ip.preco_unitario * ip.desconto_percentual / 100 AS valor_desconto,
    ip.quantidade * ip.preco_unitario * (1 - ip.desconto_percentual / 100) AS valor_faturado
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
JOIN vendedores v ON v.id_vendedor = p.id_vendedor
JOIN itens_pedido ip ON ip.id_pedido = p.id_pedido
JOIN produtos pr ON pr.id_produto = ip.id_produto
WHERE p.status_pedido = 'Faturado';

SELECT * FROM vw_vendas_detalhadas ORDER BY valor_faturado DESC;

SELECT cliente, produto, valor_faturado
FROM vw_vendas_detalhadas
ORDER BY valor_faturado DESC
LIMIT 5;

SELECT *
FROM vw_vendas_detalhadas
WHERE estado = 'PR'
ORDER BY data_pedido;

-- Missão 2: desempenho dos vendedores
DROP VIEW IF EXISTS vw_desempenho_vendedores;
CREATE VIEW vw_desempenho_vendedores AS
SELECT
    id_vendedor,
    vendedor,
    equipe,
    COUNT(DISTINCT id_pedido) AS qtd_pedidos,
    SUM(quantidade) AS qtd_unidades,
    SUM(valor_faturado) AS faturamento
FROM vw_vendas_detalhadas
GROUP BY id_vendedor, vendedor, equipe;

SELECT
    vendedor,
    equipe,
    qtd_pedidos,
    faturamento,
    ROUND(faturamento / qtd_pedidos, 2) AS ticket_medio
FROM vw_desempenho_vendedores
ORDER BY faturamento DESC;

SELECT
    equipe,
    SUM(qtd_pedidos) AS qtd_pedidos,
    SUM(faturamento) AS faturamento_total
FROM vw_desempenho_vendedores
GROUP BY equipe
ORDER BY faturamento_total DESC;

-- Missão 3: desempenho dos produtos
DROP VIEW IF EXISTS vw_desempenho_produtos;
CREATE VIEW vw_desempenho_produtos AS
SELECT
    id_produto,
    produto,
    categoria,
    SUM(quantidade) AS qtd_vendida,
    COUNT(DISTINCT id_pedido) AS qtd_pedidos,
    SUM(valor_faturado) AS receita
FROM vw_vendas_detalhadas
GROUP BY id_produto, produto, categoria;

SELECT produto, qtd_vendida, receita
FROM vw_desempenho_produtos
ORDER BY receita DESC;

SELECT
    categoria,
    SUM(qtd_vendida) AS unidades_vendidas,
    SUM(receita) AS faturamento
FROM vw_desempenho_produtos
GROUP BY categoria
HAVING SUM(receita) > 2000
ORDER BY faturamento DESC;

SELECT
    produto,
    ROUND(receita / qtd_vendida, 2) AS valor_medio_por_unidade
FROM vw_desempenho_produtos
ORDER BY valor_medio_por_unidade DESC
LIMIT 3;

-- Missão 4: comportamento dos clientes
DROP VIEW IF EXISTS vw_resumo_clientes;
CREATE VIEW vw_resumo_clientes AS
SELECT
    c.id_cliente,
    c.nome,
    c.cidade,
    c.estado,
    COUNT(DISTINCT v.id_pedido) AS qtd_pedidos,
    COALESCE(SUM(v.valor_faturado), 0) AS total_gasto
FROM clientes c
LEFT JOIN vw_vendas_detalhadas v ON v.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome, c.cidade, c.estado;

SELECT
    nome,
    qtd_pedidos,
    total_gasto,
    IF(qtd_pedidos = 0, 0, ROUND(total_gasto / qtd_pedidos, 2)) AS ticket_medio
FROM vw_resumo_clientes
ORDER BY total_gasto DESC;

SELECT
    nome,
    total_gasto,
    CASE
        WHEN qtd_pedidos = 0 THEN 'Sem compras'
        WHEN total_gasto >= 5000 THEN 'VIP'
        ELSE 'Regular'
    END AS grupo
FROM vw_resumo_clientes
ORDER BY total_gasto DESC;

SELECT
    estado,
    SUM(total_gasto) AS faturamento_total,
    COUNT(*) AS clientes_cadastrados,
    ROUND(AVG(total_gasto), 2) AS media_por_cliente
FROM vw_resumo_clientes
GROUP BY estado
ORDER BY faturamento_total DESC;

-- Missão 5: painel executivo (usa as views já criadas)
SELECT
    equipe,
    SUM(qtd_pedidos) AS qtd_pedidos,
    SUM(faturamento) AS faturamento,
    ROUND(SUM(faturamento) / SUM(qtd_pedidos), 2) AS ticket_medio
FROM vw_desempenho_vendedores
GROUP BY equipe
ORDER BY faturamento DESC;

SELECT
    p.categoria,
    SUM(p.receita) AS faturamento,
    ROUND(SUM(p.receita) * 100 / (SELECT SUM(valor_faturado) FROM vw_vendas_detalhadas), 2) AS percentual_participacao
FROM vw_desempenho_produtos p
GROUP BY p.categoria
ORDER BY faturamento DESC;

SELECT
    nome,
    estado,
    total_gasto AS valor_acumulado,
    ROUND(total_gasto - (
        SELECT AVG(total_gasto) FROM vw_resumo_clientes WHERE qtd_pedidos > 0
    ), 2) AS diferenca_para_media
FROM vw_resumo_clientes
WHERE qtd_pedidos > 0
  AND total_gasto > (
        SELECT AVG(total_gasto) FROM vw_resumo_clientes WHERE qtd_pedidos > 0
  )
ORDER BY total_gasto DESC;

-- Missão 6: manutenção da view de vendedores (inclui desconto total, mantendo os campos existentes)
CREATE OR REPLACE VIEW vw_desempenho_vendedores AS
SELECT
    id_vendedor,
    vendedor,
    equipe,
    COUNT(DISTINCT id_pedido) AS qtd_pedidos,
    SUM(quantidade) AS qtd_unidades,
    SUM(valor_faturado) AS faturamento,
    SUM(valor_desconto) AS desconto_total
FROM vw_vendas_detalhadas
GROUP BY id_vendedor, vendedor, equipe;

-- Relatórios de vendedores após a alteração
SELECT vendedor, equipe, qtd_pedidos, faturamento, desconto_total,
       ROUND(faturamento / qtd_pedidos, 2) AS ticket_medio
FROM vw_desempenho_vendedores
ORDER BY faturamento DESC;

SELECT equipe, SUM(qtd_pedidos) AS qtd_pedidos, SUM(faturamento) AS faturamento_total
FROM vw_desempenho_vendedores
GROUP BY equipe
ORDER BY faturamento_total DESC;

/*
RESPOSTAS ÀS QUESTÕES DE ANÁLISE

1. Vantagem de modificar a view: a lógica de cálculo fica em um único lugar. Ao alterar a view,
todos os relatórios que dependem dela passam a refletir a mudança sem reescrita individual.

2. Consultar uma tabela original acessa os dados brutos. Consultar uma view executa a definição
armazenada (joins, filtros e agregações) e entrega o resultado já tratado, como se fosse uma tabela.

3. Não. Uma view tradicional armazena apenas a definição da consulta. Quando os dados das tabelas
de origem mudam, a view reflete essas mudanças na próxima execução, pois ela recalcula o resultado.

4. Se a view for excluída, qualquer relatório, outra view ou aplicação que a referencie passa a
falhar com erro de tabela inexistente. Por isso, antes de excluir é preciso verificar as dependências.

5. O excesso de views aninhadas (views que chamam views que chamam views) dificulta o diagnóstico de
erros e a leitura do plano de execução. Consultas com muitos joins e agregações repetidas em
camadas podem ficar lentas, especialmente quando a view é consultada com filtros que não são aplicados
antes da agregação.

PARECER GERENCIAL

Os relatórios permitem à diretoria identificar quais equipes e vendedores concentram o faturamento
efetivado e qual é o ticket médio por pedido em cada equipe. A visão de produtos mostra quais itens e
categorias geram a maior receita, separando o volume de unidades do valor financeiro gerado.
A análise de clientes revela a concentração de compras, a faixa VIP e os clientes sem compras
faturadas, que são o público prioritário para a campanha de fidelização. A comparação por estado
mostra onde estão os clientes de maior valor e onde há oportunidade de expansão. O desconto total
por vendedor indica o custo das concessões comerciais e ajuda a avaliar se elas se traduzem em
faturamento. Pedidos cancelados e pendentes foram excluídos de todos os indicadores, de modo que os
números representam apenas receita efetivada.
*/
