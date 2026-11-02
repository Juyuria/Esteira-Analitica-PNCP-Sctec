USE pncp_controladoria;

-- ============================================================================
-- PERGUNTA 1: Economia global do Poder Público
-- ============================================================================
SELECT 
    SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END) AS estimado_comparavel,
    SUM(CASE WHEN comparavel = 1 THEN economia_valor ELSE 0 END) AS economia_nominal_rs,
    ROUND(
        (SUM(CASE WHEN comparavel = 1 THEN economia_valor ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END), 0)) * 100, 
    2) AS economia_percentual
FROM fato_item_contratado;


-- ============================================================================
-- PERGUNTA 2: Concentração e risco de fornecedores
-- Parte A: Top 10 maiores fornecedores em volume financeiro e % individual
-- ============================================================================
SELECT 
    d.ni_fornecedor,
    d.nome_fornecedor,
    SUM(f.valor_total_homologado) AS volume_financeiro,
    ROUND(
        (SUM(f.valor_total_homologado) / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado)) * 100, 
    2) AS percentual_individual
FROM fato_item_contratado f
JOIN dim_fornecedor d ON f.sk_fornecedor = d.sk_fornecedor
GROUP BY d.ni_fornecedor, d.nome_fornecedor
ORDER BY volume_financeiro DESC
LIMIT 10;

-- ============================================================================
-- PERGUNTA 2 (Complemento): Percentual acumulado concentrado no Top 10
-- ============================================================================
SELECT 
    SUM(volume_financeiro) AS volume_total_top10,
    ROUND(
        (SUM(volume_financeiro) / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado)) * 100, 
    2) AS percentual_concentrado_top10
FROM (
    SELECT SUM(valor_total_homologado) AS volume_financeiro
    FROM fato_item_contratado
    GROUP BY sk_fornecedor
    ORDER BY volume_financeiro DESC
    LIMIT 10
) AS top10;


-- ============================================================================
-- PERGUNTA 3: Eficácia por modalidade
-- ============================================================================
SELECT 
    m.nome_modalidade,
    COUNT(*) AS qtd_itens,
    SUM(f.valor_total_homologado) AS volume_recursos,
    ROUND(
        (SUM(f.valor_total_homologado) / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado)) * 100, 
    2) AS percentual_volume,
    SUM(CASE WHEN f.comparavel = 1 THEN f.economia_valor ELSE 0 END) AS economia_nominal_rs,
    ROUND(
        (SUM(CASE WHEN f.comparavel = 1 THEN f.economia_valor ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.comparavel = 1 THEN f.valor_total_estimado ELSE 0 END), 0)) * 100, 
    2) AS desagio_percentual
FROM fato_item_contratado f
JOIN dim_modalidade m ON f.sk_modalidade = m.sk_modalidade
GROUP BY m.nome_modalidade
ORDER BY volume_recursos DESC;


-- ============================================================================
-- PERGUNTA 4: Tempo do ciclo de compras por órgão (mínimo de 5 itens com ciclo)
-- ============================================================================
SELECT 
    o.nome_orgao,
    COUNT(DISTINCT o.cnpj_orgao) AS qtd_unidades,
    COUNT(f.dias_ciclo) AS itens_com_ciclo,
    ROUND(AVG(f.dias_ciclo), 1) AS ciclo_medio_dias,
    MAX(f.dias_ciclo) AS ciclo_maximo_dias
FROM fato_item_contratado f
JOIN dim_orgao o ON f.sk_orgao = o.sk_orgao
GROUP BY o.nome_orgao
HAVING COUNT(f.dias_ciclo) >= 5
ORDER BY ciclo_medio_dias DESC;

-- ============================================================================
-- PERGUNTA 4 (Conferência Geral): Ciclo médio, máximo e itens sem ciclo na base
-- ============================================================================
SELECT 
    COUNT(dias_ciclo) AS itens_com_ciclo,
    ROUND(AVG(dias_ciclo), 1) AS ciclo_medio_geral,
    MAX(dias_ciclo) AS ciclo_maximo_geral,
    COUNT(*) - COUNT(dias_ciclo) AS itens_sem_ciclo
FROM fato_item_contratado;


-- ============================================================================
-- PERGUNTA 5: Distribuição regional
-- Parte A: Despesas, unidades compradoras e desconto por Região
-- ============================================================================
SELECT 
    l.regiao,
    COUNT(DISTINCT o.cnpj_orgao) AS qtd_unidades_compradoras,
    SUM(f.valor_total_homologado) AS despesa_total,
    ROUND(
        (SUM(f.valor_total_homologado) / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado)) * 100, 
    2) AS percentual_volume,
    ROUND(
        (SUM(CASE WHEN f.comparavel = 1 THEN f.economia_valor ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.comparavel = 1 THEN f.valor_total_estimado ELSE 0 END), 0)) * 100, 
    2) AS desagio_percentual
FROM fato_item_contratado f
JOIN dim_localidade l ON f.sk_localidade = l.sk_localidade
JOIN dim_orgao o ON f.sk_orgao = o.sk_orgao
GROUP BY l.regiao
ORDER BY despesa_total DESC;

-- ============================================================================
-- PERGUNTA 5 (Parte B): Despesas, unidades compradoras e desconto por UF
-- ============================================================================
SELECT 
    l.uf_sigla,
    l.regiao,
    COUNT(DISTINCT o.cnpj_orgao) AS qtd_unidades_compradoras,
    SUM(f.valor_total_homologado) AS despesa_total,
    ROUND(
        (SUM(f.valor_total_homologado) / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado)) * 100, 
    2) AS percentual_volume,
    ROUND(
        (SUM(CASE WHEN f.comparavel = 1 THEN f.economia_valor ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.comparavel = 1 THEN f.valor_total_estimado ELSE 0 END), 0)) * 100, 
    2) AS desagio_percentual
FROM fato_item_contratado f
JOIN dim_localidade l ON f.sk_localidade = l.sk_localidade
JOIN dim_orgao o ON f.sk_orgao = o.sk_orgao
GROUP BY l.uf_sigla, l.regiao
ORDER BY despesa_total DESC;


-- ============================================================================
-- PERGUNTA 6: Perfil dos gastos (Bens, Serviços e Obras)
-- ============================================================================
SELECT 
    perfil_gasto,
    COUNT(*) AS qtd_itens,
    SUM(valor_total_homologado) AS volume_recursos,
    ROUND(
        (SUM(valor_total_homologado) / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado)) * 100, 
    2) AS percentual_volume,
    ROUND(SUM(valor_total_homologado) / COUNT(*), 2) AS ticket_medio
FROM fato_item_contratado
GROUP BY perfil_gasto
ORDER BY volume_recursos DESC;