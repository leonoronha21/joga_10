CREATE TABLE IF NOT EXISTS usuario (
  id SERIAL PRIMARY KEY,
  primeiro_nome TEXT NOT NULL,
  segundo_nome TEXT,
  email TEXT NOT NULL UNIQUE,
  senha_hash TEXT NOT NULL,
  cidade TEXT,
  bairro TEXT,
  rua TEXT,
  complemento TEXT,
  contato TEXT,
  role TEXT NOT NULL DEFAULT 'USER',
  foto BYTEA,
  foto_verificada BOOLEAN NOT NULL DEFAULT false,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS estabelecimento (
  id SERIAL PRIMARY KEY,
  cnpj TEXT,
  nome TEXT NOT NULL,
  razao_social TEXT,
  cidade TEXT,
  cep TEXT,
  rua TEXT,
  bairro TEXT,
  numero TEXT,
  hora_abertura TIME,
  hora_fechamento TIME,
  telefone TEXT,
  email TEXT,
  status INTEGER NOT NULL DEFAULT 0,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS quadra (
  id SERIAL PRIMARY KEY,
  id_estabelecimento INTEGER NOT NULL REFERENCES estabelecimento(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  tipo_quadra TEXT NOT NULL,
  preco NUMERIC(10,2) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS partida (
  id SERIAL PRIMARY KEY,
  id_estabelecimento INTEGER REFERENCES estabelecimento(id) ON DELETE SET NULL,
  id_quadra INTEGER REFERENCES quadra(id) ON DELETE SET NULL,
  organizador_id INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  duracao TEXT,
  data_hora TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'AGENDADA',
  preco NUMERIC(10,2) NOT NULL DEFAULT 0,
  visibilidade TEXT NOT NULL DEFAULT 'PUBLICA',
  modalidade TEXT NOT NULL DEFAULT 'FUTEBOL',
  formato TEXT NOT NULL DEFAULT '5x5',
  formacao_time1 TEXT,
  formacao_time2 TEXT,
  placar_time1 INTEGER,
  placar_time2 INTEGER,
  grupo_recorrencia TEXT,
  recorrencia TEXT NOT NULL DEFAULT 'NENHUMA',
  recorrencia_ate TIMESTAMPTZ,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS partida_membro (
  id SERIAL PRIMARY KEY,
  partida_id INTEGER NOT NULL REFERENCES partida(id) ON DELETE CASCADE,
  id_user INTEGER REFERENCES usuario(id) ON DELETE SET NULL,
  equipe TEXT NOT NULL DEFAULT 'TIME_1',
  nome TEXT NOT NULL,
  telefone TEXT,
  capitao BOOLEAN NOT NULL DEFAULT FALSE,
  pos_x DOUBLE PRECISION,
  pos_y DOUBLE PRECISION,
  gols INTEGER NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_partida_capitao_time
  ON partida_membro(partida_id, equipe)
  WHERE capitao = TRUE;

CREATE TABLE IF NOT EXISTS partida_rateio (
  id SERIAL PRIMARY KEY,
  partida_id INTEGER NOT NULL UNIQUE REFERENCES partida(id) ON DELETE CASCADE,
  valor_quadra NUMERIC(10,2) NOT NULL,
  taxa_percentual NUMERIC(5,2) NOT NULL DEFAULT 2.5,
  status TEXT NOT NULL DEFAULT 'ABERTO',
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rateio_cobranca (
  id SERIAL PRIMARY KEY,
  rateio_id INTEGER NOT NULL REFERENCES partida_rateio(id) ON DELETE CASCADE,
  partida_membro_id INTEGER REFERENCES partida_membro(id) ON DELETE SET NULL,
  id_user INTEGER REFERENCES usuario(id) ON DELETE SET NULL,
  nome TEXT NOT NULL,
  valor_quadra NUMERIC(10,2) NOT NULL,
  taxa_servico NUMERIC(10,2) NOT NULL DEFAULT 0,
  valor_total NUMERIC(10,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDENTE',
  pago_em TIMESTAMPTZ,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (rateio_id, partida_membro_id)
);

CREATE TABLE IF NOT EXISTS pagamento_transacao (
  id SERIAL PRIMARY KEY,
  cobranca_id INTEGER NOT NULL REFERENCES rateio_cobranca(id) ON DELETE CASCADE,
  provedor TEXT NOT NULL,
  referencia_externa TEXT NOT NULL UNIQUE,
  valor NUMERIC(10,2) NOT NULL,
  status TEXT NOT NULL,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS usuario_gamificacao (
  usuario_id INTEGER PRIMARY KEY REFERENCES usuario(id) ON DELETE CASCADE,
  pontos INTEGER NOT NULL DEFAULT 0,
  partidas_confirmadas INTEGER NOT NULL DEFAULT 0,
  pagamentos_em_dia INTEGER NOT NULL DEFAULT 0,
  pagamentos_pendentes INTEGER NOT NULL DEFAULT 0,
  confiabilidade NUMERIC(5,2) NOT NULL DEFAULT 100,
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS plano_assinatura (
  id SERIAL PRIMARY KEY,
  codigo TEXT NOT NULL UNIQUE,
  nome TEXT NOT NULL,
  descricao TEXT,
  preco_mensal NUMERIC(10,2) NOT NULL DEFAULT 0,
  ativo BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS assinatura_usuario (
  id SERIAL PRIMARY KEY,
  usuario_id INTEGER NOT NULL UNIQUE REFERENCES usuario(id) ON DELETE CASCADE,
  plano_id INTEGER NOT NULL REFERENCES plano_assinatura(id),
  status TEXT NOT NULL DEFAULT 'ATIVA',
  inicio_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  fim_em TIMESTAMPTZ,
  origem TEXT NOT NULL DEFAULT 'LOCAL_DEMO',
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS postagem (
  id SERIAL PRIMARY KEY,
  autor_id INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  texto TEXT,
  foto BYTEA,
  partida_id INTEGER REFERENCES partida(id) ON DELETE SET NULL,
  tipo TEXT NOT NULL DEFAULT 'PUBLICACAO',
  visibilidade TEXT NOT NULL DEFAULT 'PUBLICO',
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS curtida (
  postagem_id INTEGER NOT NULL REFERENCES postagem(id) ON DELETE CASCADE,
  usuario_id INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (postagem_id, usuario_id)
);

CREATE TABLE IF NOT EXISTS comentario (
  id SERIAL PRIMARY KEY,
  postagem_id INTEGER NOT NULL REFERENCES postagem(id) ON DELETE CASCADE,
  autor_id INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  texto TEXT NOT NULL,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS amizade (
  id SERIAL PRIMARY KEY,
  solicitante_id INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  destinatario_id INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'PENDENTE',
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (solicitante_id, destinatario_id),
  CHECK (solicitante_id <> destinatario_id)
);

CREATE TABLE IF NOT EXISTS goleiro (
  id SERIAL PRIMARY KEY,
  usuario_id INTEGER NOT NULL UNIQUE REFERENCES usuario(id) ON DELETE CASCADE,
  cidade TEXT,
  preco_jogo NUMERIC(10,2) NOT NULL DEFAULT 0,
  nivel INTEGER NOT NULL DEFAULT 3,
  disponivel BOOLEAN NOT NULL DEFAULT true,
  observacao TEXT
);

CREATE TABLE IF NOT EXISTS contratacao_goleiro (
  id SERIAL PRIMARY KEY,
  goleiro_id INTEGER NOT NULL REFERENCES goleiro(id) ON DELETE CASCADE,
  partida_id INTEGER REFERENCES partida(id) ON DELETE SET NULL,
  solicitante_id INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'PENDENTE',
  valor NUMERIC(10,2),
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cartao (
  id SERIAL PRIMARY KEY,
  id_user INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  nome_titular TEXT NOT NULL,
  bandeira TEXT,
  ultimos4 VARCHAR(4) NOT NULL,
  validade TEXT NOT NULL,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS clube (
  id SERIAL PRIMARY KEY,
  nome TEXT NOT NULL,
  cidade TEXT,
  cor TEXT NOT NULL DEFAULT '#1B3A6B',
  dono_id INTEGER REFERENCES usuario(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS clube_jogador (
  id SERIAL PRIMARY KEY,
  clube_id INTEGER NOT NULL REFERENCES clube(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  posicao TEXT,
  numero INTEGER,
  pos_x DOUBLE PRECISION,
  pos_y DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS liga (
  id SERIAL PRIMARY KEY,
  nome TEXT NOT NULL,
  cidade TEXT,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS liga_clube (
  liga_id INTEGER NOT NULL REFERENCES liga(id) ON DELETE CASCADE,
  clube_id INTEGER NOT NULL REFERENCES clube(id) ON DELETE CASCADE,
  PRIMARY KEY (liga_id, clube_id)
);

CREATE TABLE IF NOT EXISTS confronto (
  id SERIAL PRIMARY KEY,
  clube_casa_id INTEGER NOT NULL REFERENCES clube(id) ON DELETE CASCADE,
  clube_visitante_id INTEGER NOT NULL REFERENCES clube(id) ON DELETE CASCADE,
  data_hora TIMESTAMPTZ NOT NULL,
  tipo TEXT NOT NULL DEFAULT 'AMISTOSO',
  local TEXT,
  liga_id INTEGER REFERENCES liga(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'AGENDADO',
  placar_casa INTEGER,
  placar_visitante INTEGER,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (clube_casa_id <> clube_visitante_id)
);

CREATE INDEX IF NOT EXISTS idx_partida_data_hora ON partida(data_hora DESC);
CREATE INDEX IF NOT EXISTS idx_rateio_cobranca_usuario ON rateio_cobranca(id_user, status);
CREATE INDEX IF NOT EXISTS idx_rateio_cobranca_rateio ON rateio_cobranca(rateio_id);
CREATE INDEX IF NOT EXISTS idx_pagamento_transacao_cobranca ON pagamento_transacao(cobranca_id, criado_em DESC);
CREATE INDEX IF NOT EXISTS idx_postagem_autor_criado ON postagem(autor_id, criado_em DESC);
CREATE INDEX IF NOT EXISTS idx_amizade_solicitante ON amizade(solicitante_id);
CREATE INDEX IF NOT EXISTS idx_amizade_destinatario ON amizade(destinatario_id);
CREATE INDEX IF NOT EXISTS idx_confronto_liga ON confronto(liga_id);

INSERT INTO usuario (
  id,
  primeiro_nome,
  segundo_nome,
  email,
  senha_hash,
  cidade,
  bairro,
  rua,
  complemento,
  contato,
  role
) VALUES (
  0,
  'Admin',
  'Local',
  'admin',
  crypt('123', gen_salt('bf')),
  'Sao Paulo',
  'Local',
  'Ambiente local',
  'Usuario setado no codigo',
  '(11) 99999-0001',
  'ADMIN'
) ON CONFLICT (id) DO UPDATE SET
  primeiro_nome = EXCLUDED.primeiro_nome,
  segundo_nome = EXCLUDED.segundo_nome,
  email = EXCLUDED.email,
  senha_hash = EXCLUDED.senha_hash,
  cidade = EXCLUDED.cidade,
  bairro = EXCLUDED.bairro,
  rua = EXCLUDED.rua,
  complemento = EXCLUDED.complemento,
  contato = EXCLUDED.contato,
  role = EXCLUDED.role;

INSERT INTO usuario (
  primeiro_nome,
  segundo_nome,
  email,
  senha_hash,
  cidade,
  bairro,
  rua,
  complemento,
  contato,
  role
) VALUES (
  'Usuario',
  'Teste',
  'teste@joga10.com',
  crypt('123456', gen_salt('bf')),
  'Sao Paulo',
  'Centro',
  'Rua Local',
  'Ambiente de teste',
  '(11) 99999-0000',
  'USER'
) ON CONFLICT (email) DO UPDATE SET
  primeiro_nome = EXCLUDED.primeiro_nome,
  segundo_nome = EXCLUDED.segundo_nome,
  senha_hash = EXCLUDED.senha_hash,
  cidade = EXCLUDED.cidade,
  bairro = EXCLUDED.bairro,
  rua = EXCLUDED.rua,
  complemento = EXCLUDED.complemento,
  contato = EXCLUDED.contato,
  role = EXCLUDED.role;

SELECT setval(
  pg_get_serial_sequence('usuario', 'id'),
  GREATEST((SELECT COALESCE(MAX(id), 0) FROM usuario), 1),
  true
);

INSERT INTO plano_assinatura (codigo, nome, descricao, preco_mensal)
VALUES
  ('FREE', 'Joga10 Free', 'Partidas e convites, com taxa de 2,5% em cada rateio.', 0),
  ('PRO', 'Joga10 Pro', 'Campeonatos e rateios sem taxa.', 14.90)
ON CONFLICT (codigo) DO UPDATE SET
  nome = EXCLUDED.nome,
  descricao = EXCLUDED.descricao,
  preco_mensal = EXCLUDED.preco_mensal,
  ativo = true;

INSERT INTO usuario_gamificacao (usuario_id)
SELECT id FROM usuario
ON CONFLICT (usuario_id) DO NOTHING;

INSERT INTO estabelecimento (
  cnpj,
  nome,
  razao_social,
  cidade,
  cep,
  rua,
  bairro,
  numero,
  hora_abertura,
  hora_fechamento,
  telefone,
  email,
  status,
  latitude,
  longitude
)
SELECT
  '00000000000100',
  'Arena Joga10 Local',
  'Arena Joga10 Local LTDA',
  'Sao Paulo',
  '01000-000',
  'Rua Local',
  'Centro',
  '10',
  '08:00'::time,
  '23:00'::time,
  '(11) 3333-0000',
  'arena@joga10.local',
  1,
  -23.550520,
  -46.633308
WHERE NOT EXISTS (
  SELECT 1 FROM estabelecimento WHERE nome = 'Arena Joga10 Local'
);

INSERT INTO quadra (id_estabelecimento, nome, tipo_quadra, preco)
SELECT e.id, 'Campo Society', 'Futebol Society', 120.00
FROM estabelecimento e
WHERE e.nome = 'Arena Joga10 Local'
  AND NOT EXISTS (
    SELECT 1 FROM quadra q
    WHERE q.id_estabelecimento = e.id AND q.nome = 'Campo Society'
  );

INSERT INTO quadra (id_estabelecimento, nome, tipo_quadra, preco)
SELECT e.id, 'Quadra de Volei', 'Volei', 100.00
FROM estabelecimento e
WHERE e.nome = 'Arena Joga10 Local'
  AND NOT EXISTS (
    SELECT 1 FROM quadra q
    WHERE q.id_estabelecimento = e.id AND q.nome = 'Quadra de Volei'
  );

INSERT INTO partida (
  id_estabelecimento,
  id_quadra,
  organizador_id,
  duracao,
  data_hora,
  status,
  preco
)
SELECT
  e.id,
  q.id,
  admin.id,
  '1h',
  date_trunc('day', now()) + interval '7 days 19 hours',
  'AGENDADA',
  q.preco
FROM estabelecimento e
JOIN quadra q ON q.id_estabelecimento = e.id
JOIN usuario admin ON admin.email = 'admin'
WHERE e.nome = 'Arena Joga10 Local'
  AND q.nome = 'Campo Society'
  AND NOT EXISTS (
    SELECT 1 FROM partida p
    WHERE p.organizador_id = admin.id
      AND p.id_quadra = q.id
      AND p.status = 'AGENDADA'
  );

INSERT INTO partida_membro (partida_id, id_user, equipe, nome)
SELECT p.id, u.id, 'TIME_1', u.primeiro_nome || ' ' || COALESCE(u.segundo_nome, '')
FROM partida p
JOIN usuario u ON u.email = 'admin'
WHERE p.organizador_id = u.id
  AND p.status = 'AGENDADA'
  AND NOT EXISTS (
    SELECT 1 FROM partida_membro pm
    WHERE pm.partida_id = p.id AND pm.id_user = u.id
  );

INSERT INTO partida_membro (partida_id, id_user, equipe, nome)
SELECT p.id, u.id, 'TIME_2', u.primeiro_nome || ' ' || COALESCE(u.segundo_nome, '')
FROM partida p
JOIN usuario u ON u.email = 'teste@joga10.com'
WHERE p.status = 'AGENDADA'
  AND p.organizador_id = (SELECT id FROM usuario WHERE email = 'admin')
  AND NOT EXISTS (
    SELECT 1 FROM partida_membro pm
    WHERE pm.partida_id = p.id AND pm.id_user = u.id
  );

INSERT INTO postagem (autor_id, texto)
SELECT u.id, 'Conta de teste criada no banco local.'
FROM usuario u
WHERE u.email = 'teste@joga10.com'
  AND NOT EXISTS (
    SELECT 1 FROM postagem p
    WHERE p.autor_id = u.id
      AND p.texto = 'Conta de teste criada no banco local.'
  );
