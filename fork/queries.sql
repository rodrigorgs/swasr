-- Reunião 24/nov/2009
-- Que áreas nenhum algoritmo se dá bem?
-- Que áreas todos se saem bem?
-- Roberto: como os parâmetros se distribuem em sistemas reais? fator de mistura (mínimo e máximo)
  -- TODO: plotar distribuições de métricas nas redes
-- TODO: disponibilizar dados para Dalton, Jorge e Roberto
-- Se entregar final de janeiro, em 10 dias jorge/dalton entregam revisão

-- tese completa

-- 15/20 dias para experimentos com algoritmos

-- minhas dúvidas (como encaminhar os experimentos <- escrever e-mail)
---- como samplear se a distribuição não é normal?
---- e se meus dados têm algum bias?

--
-- Quantidade de redes sintéticas realistas clusterizados por todos os algoritmos, por modelo
--
SELECT nme_model, COUNT(*)
FROM
    (SELECT nme_model, pk_network, COUNT(*)
    FROM view_decomposition
    WHERE synthetic
    AND s_score > 0.9
    GROUP BY 1, 2
    HAVING COUNT(*) = 8) AS x
GROUP BY 1

--
-- MoJoSim médio de cada algoritmo de clustering nas redes se software
--
-- Resultado: o ranking é Infomap (0.84), ACDC (0.82), CL90 (0.72), SL75 (0.65), Bunch (0.63), SL90 (0.61), CL75 (0.56)
-- (entre parêntereses os mojosims médios)
-- 
SELECT nme_clusterer_config, AVG(mojosim) AS avg_mojosim, AVG(nmi) AS avg_nmi, AVG(n_modules) AS avg_mods, AVG(n_vertices / n_modules) AS verts_per_mod
FROM view_decomposition
WHERE fk_network IN (43,6,23,5,2,62,35,9,42,61,28,44,16,21,32,10,55,25,7,58,46,56,15,1,53,12,47,17,24,64,52,50,29,26)
GROUP by 1
ORDER by 2 DESC;

--
-- MoJoSim médio de cada algoritmo de clustering nas redes sintéticas realistas, por modelo
--
-- Resultado: Todos os algoritmos de clustering se saem melhor nas redes BCR+ e pior nas redes CGW.
--
SELECT nme_clusterer_config, nme_model, AVG(mojosim) AS avg_mojosim, AVG(nmi) AS avg_nmi, AVG(n_modules) AS avg_mods, AVG(n_vertices / n_modules) AS verts_per_mod
FROM view_decomposition
WHERE pk_network IN
    (SELECT pk_network
    FROM view_decomposition
    WHERE synthetic
    AND s_score > 0.9
    GROUP BY 1
    HAVING COUNT(*) = 8)
GROUP by 1, 2
ORDER by 1, 3;

--
-- MoJoSim médio de cada algoritmo de clustering nas redes sintéticas realistas, por modelo
--
-- Ranking:
--   BCR+: ACDC, Infomap, Bunch
--   CGW: CL90, Infomap, ACDC
--   LF: Infomap, CL90, Bunch
--
SELECT nme_clusterer_config, nme_model, AVG(mojosim) AS avg_mojosim, AVG(nmi) AS avg_nmi, AVG(n_modules) AS avg_mods, AVG(n_vertices / n_modules) AS verts_per_mod
FROM view_decomposition
WHERE pk_network IN
    (SELECT pk_network
    FROM view_decomposition
    WHERE synthetic
    AND s_score > 0.9
    GROUP BY 1
    HAVING COUNT(*) = 8)
GROUP by 1, 2
ORDER by 2, 3 DESC;

--
-- MoJoSim médio de cada algoritmo de clustering nas redes sintéticas realistas, geral
--
-- Ranking:
--   Bunch (0.64), Infomap (0.51), CL90 (0.49) -- MoJoSim
--   SL75 (0.56), CL75 (0.54), CL90 (0.53) -- NMI
--
SELECT nme_clusterer_config, AVG(mojosim) AS avg_mojosim, AVG(nmi) AS avg_nmi, AVG(n_modules) AS avg_mods, AVG(n_vertices / n_modules) AS verts_per_mod
FROM view_decomposition
WHERE pk_network IN
    (SELECT pk_network
    FROM view_decomposition
    WHERE synthetic
    AND s_score > 0.9
    GROUP BY 1
    HAVING COUNT(*) = 8)
GROUP by 1
ORDER by 2 DESC;

--
-- O que mais afeta o MoJoSim de uma rede sintética? 
--
SELECT nme_clusterer_config, 
n_modules / n_vertices::float AS rel_n_modules, 
min_module_size / n_vertices::float AS rel_min_module_size, 
max_module_size / n_vertices::float AS rel_max_module_size,
s_score, n_edges, min_indegree, max_indegree, max_outdegree, min_outdegree, sum_indegree, sum_outdegree,
mojosim
FROM view_decomposition
WHERE pk_network IN
    (SELECT pk_network
    FROM view_decomposition
    WHERE synthetic
    AND s_score > 0.9
    GROUP BY 1
    HAVING COUNT(*) = 8)
AND fk_clusterer_config IS NOT NULL
AND n_modules IS NOT NULL
AND s_score IS NOT NULL
AND min_indegree IS NOT NULL