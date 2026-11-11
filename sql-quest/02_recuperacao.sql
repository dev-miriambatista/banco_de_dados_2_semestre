USE sql_quest;

SET SQL_SAFE_UPDATES = 0;

-- Etapa 1: classificação
UPDATE jogadores
SET classificacao = CASE
    WHEN pontos >= 12000 THEN 'LENDÁRIO'
    WHEN pontos >= 8000 THEN 'ELITE'
    WHEN pontos >= 5000 THEN 'VETERANO'
    ELSE 'APRENDIZ'
END;

-- Etapa 2: bônus NULL passa a ser zero
UPDATE jogadores
SET bonus = COALESCE(bonus, 0)
WHERE bonus IS NULL;

-- Etapa 3: +250 moedas para quem está acima da média de pontos
-- A subconsulta fica em uma tabela derivada para evitar o erro 1093 do MySQL
UPDATE jogadores
SET moedas = moedas + 250
WHERE pontos > (
    SELECT media FROM (
        SELECT AVG(pontos) AS media FROM jogadores
    ) AS m
);

-- Etapa 4: +300 moedas para membros das guildas com média acima de 7000
UPDATE jogadores
SET moedas = moedas + 300
WHERE guilda IN (
    SELECT guilda FROM (
        SELECT guilda
        FROM jogadores
        WHERE guilda IS NOT NULL
        GROUP BY guilda
        HAVING AVG(pontos) > 7000
    ) AS g
);

-- Etapa 5: os três maiores em pontos sobem um nível
UPDATE jogadores
SET nivel = nivel + 1
WHERE id IN (
    SELECT id FROM (
        SELECT id FROM jogadores ORDER BY pontos DESC LIMIT 3
    ) AS top3
);

-- Etapa 6: conferência antes do treinamento
SELECT id, nome, nivel, status_jogador
FROM jogadores
WHERE status_jogador = 'ATIVO' AND nivel < 18;

UPDATE jogadores
SET nivel = nivel + 2
WHERE status_jogador = 'ATIVO' AND nivel < 18;

-- Etapa 7: conferência antes da exclusão
SELECT id, nome, status_jogador, pontos
FROM jogadores
WHERE status_jogador = 'INATIVO' AND pontos < 2000;

DELETE FROM jogadores
WHERE status_jogador = 'INATIVO' AND pontos < 2000;

-- Auditoria final
SELECT id, nome, nivel, moedas, pontos, guilda, bonus, status_jogador, classificacao
FROM jogadores
ORDER BY pontos DESC;

SET SQL_SAFE_UPDATES = 1;
