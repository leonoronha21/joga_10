import { execFileSync } from 'node:child_process';

const projectId = process.env.FIREBASE_PROJECT_ID ?? 'joga10-ec65f';
const demoUserUid = process.env.DEMO_USER_UID;
const firebaseCommand = process.platform === 'win32' ? 'firebase.cmd' : 'firebase';
const login = JSON.parse(
  execFileSync(firebaseCommand, ['login:list', '--json'], {
    encoding: 'utf8',
    shell: process.platform === 'win32',
  }),
);
const accessToken = login.result?.[0]?.tokens?.access_token;

if (!accessToken) {
  throw new Error('Execute "firebase login" antes de carregar os dados demo.');
}

const databaseRoot =
  `projects/${projectId}/databases/(default)/documents`;
const now = new Date();

const ids = {
  admin: 'usuario-admin-demo',
  bruno: 'usuario-bruno-demo',
  carla: 'usuario-carla-demo',
  diego: 'usuario-diego-demo',
  ana: 'usuario-ana-demo',
  arena: 'estabelecimento-arena-moinhos',
  ibirapuera: 'estabelecimento-marinha',
  vila: 'estabelecimento-redencao',
  society: 'quadra-society-principal',
  futsal: 'quadra-futsal',
  campo7: 'quadra-campo-7',
  basquete: 'quadra-basquete-coberto',
  areia: 'quadra-areia-premium',
  partida1: 'partida-sexta-demo',
  partida2: 'partida-campo7-demo',
  partida3: 'partida-finalizada-demo',
  liga: 'liga-poa-demo',
  clubeBomfim: 'clube-bomfim-demo',
  clubeCidadeBaixa: 'clube-cidadebaixa-demo',
  clubeZonaSul: 'clube-zonasul-demo',
  clubeTristeza: 'clube-tristeza-demo',
  confronto1: 'confronto-1-demo',
  confronto2: 'confronto-2-demo',
  confronto3: 'confronto-3-demo',
  confronto4: 'confronto-4-demo',
  goleiroParedao: 'goleiro-paredao-demo',
  goleiroLuvas: 'goleiro-luvas-demo',
};

const usuarios = [
  [ids.admin, 'Admin', 'Local', 'admin@demo.joga10.app', 'ADMIN'],
  [ids.bruno, 'Bruno', 'Silva', 'bruno@demo.joga10.app', 'USER'],
  [ids.carla, 'Carla', 'Mendes', 'carla@demo.joga10.app', 'USER'],
  [ids.diego, 'Diego', 'Costa', 'diego@demo.joga10.app', 'USER'],
  [ids.ana, 'Ana', 'Lima', 'ana@demo.joga10.app', 'USER'],
].map(([id, primeiroNome, segundoNome, email, role]) => ({
  path: `usuarios/${id}`,
  data: {
    primeiroNome,
    segundoNome,
    nomeCompleto: `${primeiroNome} ${segundoNome}`,
    email,
    cidade: 'Porto Alegre',
    role,
    ambiente: 'DEMO',
    ativo: true,
    criadoEm: now,
  },
}));

const usuariosPublicos = usuarios.map(({ path, data }) => ({
  path: path.replace('usuarios/', 'usuariosPublicos/'),
  data: {
    primeiroNome: data.primeiroNome,
    segundoNome: data.segundoNome,
    nomeCompleto: data.nomeCompleto,
    cidade: data.cidade,
    ativo: true,
    criadoEm: now,
  },
}));

const estabelecimentos = [
  [ids.arena, 'Arena Joga10 Moinhos', 'Moinhos de Vento', 'Rua Padre Chagas', '100', -30.0247, -51.2030],
  [ids.ibirapuera, 'Centro Esportivo Marinha do Brasil', 'Praia de Belas', 'Av. Edvaldo Pereira Paiva', '200', -30.0577, -51.2370],
  [ids.vila, 'Quadras Parque da Redenção', 'Bom Fim', 'Av. João Pessoa', '88', -30.0395, -51.2160],
].map(([id, nome, bairro, rua, numero, latitude, longitude]) => ({
  path: `estabelecimentos/${id}`,
  data: {
    nome,
    cidade: 'Porto Alegre',
    bairro,
    rua,
    numero,
    latitude,
    longitude,
    horaAbertura: '08:00',
    horaFechamento: '23:00',
    status: 'ATIVO',
    ambiente: 'DEMO',
  },
}));

const quadras = [
  [ids.society, ids.arena, 'Society Principal', 'Futebol Society', 180],
  [ids.futsal, ids.arena, 'Quadra de Futsal', 'Futsal', 140],
  [ids.campo7, ids.ibirapuera, 'Campo 7', 'Futebol Society', 210],
  [ids.basquete, ids.ibirapuera, 'Basquete Coberto', 'Basquete', 110],
  [ids.areia, ids.vila, 'Areia Premium', 'Volei', 130],
].map(([id, estabelecimentoId, nome, tipoQuadra, preco]) => ({
  path: `quadras/${id}`,
  data: {
    estabelecimentoId,
    nome,
    tipoQuadra,
    preco,
    ativa: true,
    ambiente: 'DEMO',
  },
}));

const partidas = [
  {
    path: `partidas/${ids.partida1}`,
    data: {
      organizadorId: ids.admin,
      estabelecimentoId: ids.arena,
      estabelecimentoNome: 'Arena Joga10 Moinhos',
      quadraId: ids.society,
      quadraNome: 'Society Principal',
      dataHora: daysFromNow(3),
      duracao: '1h',
      status: 'AGENDADA',
      preco: 180,
      visibilidade: 'PUBLICA',
      participantesUids: [ids.admin, ids.bruno, ids.carla, ids.diego, ids.ana],
      modalidade: 'FUTEBOL',
      formato: '5x5',
      ambiente: 'DEMO',
    },
  },
  {
    path: `partidas/${ids.partida2}`,
    data: {
      organizadorId: ids.bruno,
      estabelecimentoId: ids.ibirapuera,
      estabelecimentoNome: 'Centro Esportivo Marinha do Brasil',
      quadraId: ids.campo7,
      quadraNome: 'Campo 7',
      dataHora: daysFromNow(9),
      duracao: '1h30',
      status: 'AGENDADA',
      preco: 210,
      visibilidade: 'PUBLICA',
      participantesUids: [ids.admin, ids.bruno, ids.diego],
      modalidade: 'FUTEBOL',
      formato: '7x7',
      ambiente: 'DEMO',
    },
  },
  {
    path: `partidas/${ids.partida3}`,
    data: {
      organizadorId: ids.admin,
      estabelecimentoId: ids.arena,
      estabelecimentoNome: 'Arena Joga10 Moinhos',
      quadraId: ids.futsal,
      quadraNome: 'Quadra de Futsal',
      dataHora: daysFromNow(-5),
      duracao: '1h',
      status: 'FINALIZADA',
      preco: 140,
      visibilidade: 'PUBLICA',
      participantesUids: [ids.admin, ids.bruno, ids.carla, ids.diego, ids.ana],
      modalidade: 'FUTEBOL',
      formato: '5x5',
      placarTime1: 6,
      placarTime2: 4,
      ambiente: 'DEMO',
    },
  },
];

const membros = [
  [ids.partida1, ids.admin, 'Admin Local', 'TIME_1', 0],
  [ids.partida1, ids.bruno, 'Bruno Silva', 'TIME_1', 0],
  [ids.partida1, ids.carla, 'Carla Mendes', 'TIME_1', 0],
  [ids.partida1, ids.diego, 'Diego Costa', 'TIME_2', 0],
  [ids.partida1, ids.ana, 'Ana Lima', 'TIME_2', 0],
  [ids.partida2, ids.admin, 'Admin Local', 'TIME_2', 0],
  [ids.partida2, ids.bruno, 'Bruno Silva', 'TIME_1', 0],
  [ids.partida2, ids.diego, 'Diego Costa', 'TIME_1', 0],
  [ids.partida3, ids.admin, 'Admin Local', 'TIME_1', 2],
  [ids.partida3, ids.bruno, 'Bruno Silva', 'TIME_1', 3],
  [ids.partida3, ids.carla, 'Carla Mendes', 'TIME_1', 1],
  [ids.partida3, ids.diego, 'Diego Costa', 'TIME_2', 2],
  [ids.partida3, ids.ana, 'Ana Lima', 'TIME_2', 2],
].map(([partidaId, usuarioId, nome, equipe, gols]) => ({
  path: `partidas/${partidaId}/membros/${usuarioId}`,
  data: { usuarioId, nome, equipe, gols, ambiente: 'DEMO' },
}));

// ---- Campeonatos (liga, clubes, classificação) ----
const clubesInfo = [
  [ids.clubeBomfim, 'Bom Fim FC', '#1B3A6B'],
  [ids.clubeCidadeBaixa, 'Cidade Baixa United', '#C0392B'],
  [ids.clubeZonaSul, 'Zona Sul SC', '#27AE60'],
  [ids.clubeTristeza, 'Tristeza EC', '#E67E22'],
];
const corDe = Object.fromEntries(
  clubesInfo.map(([id, nome, cor]) => [id, { nome, cor }]),
);

const clubes = clubesInfo.map(([id, nome, cor]) => ({
  path: `clubes/${id}`,
  data: {
    nome,
    cidade: 'Porto Alegre',
    cor,
    donoId: ids.admin,
    ambiente: 'DEMO',
    criadoEm: now,
  },
}));

const liga = {
  path: `ligas/${ids.liga}`,
  data: {
    nome: 'Liga Joga10 Porto Alegre',
    cidade: 'Porto Alegre',
    donoId: ids.admin,
    ambiente: 'DEMO',
    criadoEm: now,
  },
};

const ligaClubes = clubesInfo.map(([id, nome, cor]) => ({
  path: `ligaClubes/${ids.liga}_${id}`,
  data: {
    ligaId: ids.liga,
    clubeId: id,
    nome,
    cidade: 'Porto Alegre',
    cor,
    donoId: ids.admin,
  },
}));

const confrontos = [
  [ids.confronto1, ids.clubeBomfim, ids.clubeCidadeBaixa, 'REALIZADO', 3, 1, -12],
  [ids.confronto2, ids.clubeZonaSul, ids.clubeTristeza, 'REALIZADO', 2, 2, -10],
  [ids.confronto3, ids.clubeBomfim, ids.clubeZonaSul, 'REALIZADO', 0, 2, -3],
  [ids.confronto4, ids.clubeCidadeBaixa, ids.clubeTristeza, 'AGENDADO', null, null, 5],
].map(([id, casa, visitante, status, placarCasa, placarVisitante, dias]) => ({
  path: `confrontos/${id}`,
  data: {
    ligaId: ids.liga,
    clubeCasaId: casa,
    clubeCasaNome: corDe[casa].nome,
    clubeCasaCor: corDe[casa].cor,
    clubeVisitanteId: visitante,
    clubeVisitanteNome: corDe[visitante].nome,
    clubeVisitanteCor: corDe[visitante].cor,
    dataHora: daysFromNow(dias),
    tipo: 'OFICIAL',
    local: 'Porto Alegre',
    status,
    placarCasa,
    placarVisitante,
    donoId: ids.admin,
    ambiente: 'DEMO',
    criadoEm: now,
  },
}));

const clubeJogadores = [
  ['Léo', 'GOL', 1],
  ['Maurício', 'ZAG', 4],
  ['Pedro', 'MEI', 8],
  ['Júnior', 'ATA', 9],
  ['Rafa', 'ATA', 11],
].map(([nome, posicao, numero], i) => ({
  path: `clubeJogadores/${ids.clubeBomfim}-jog-${i}`,
  data: {
    clubeId: ids.clubeBomfim,
    nome,
    posicao,
    numero,
    posX: null,
    posY: null,
    donoId: ids.admin,
    ambiente: 'DEMO',
  },
}));

// ---- Goleiros disponíveis ----
const goleiros = [
  [ids.goleiroParedao, 'Rafael Paredão', 60, 5, '(51) 99999-1111', 'Reflexos rápidos e boa saída de bola.'],
  [ids.goleiroLuvas, 'Tiago Luvas de Ouro', 45, 4, '(51) 99999-2222', 'Especialista em pênaltis.'],
].map(([id, nome, precoJogo, nivel, contato, observacao]) => ({
  path: `goleiros/${id}`,
  data: {
    usuarioId: id,
    nome,
    contato,
    cidade: 'Porto Alegre',
    precoJogo,
    nivel,
    disponivel: true,
    observacao,
    ambiente: 'DEMO',
    atualizadoEm: now,
  },
}));

const configuracao = {
  path: 'configuracoes/migracao-demo',
  data: {
    schemaVersion: 1,
    ambiente: 'DEMO',
    fotosHabilitadas: false,
    pagamentosReaisHabilitados: false,
    atualizadoEm: now,
  },
};

const postagens = [
  [ids.admin, 'Admin Local', 'Bem-vindo ao Descobrir do Joga10!'],
  [ids.bruno, 'Bruno Silva', 'Partida confirmada para sexta. Quem fecha o time?'],
  [ids.carla, 'Carla Mendes', 'Treino de hoje rendeu.'],
].map(([autorId, autorNome, texto], index) => ({
  path: `postagens/postagem-demo-${index + 1}`,
  data: {
    autorId,
    autorNome,
    texto,
    fotoUrl: null,
    partidaIdCompat: null,
    tipo: 'PUBLICACAO',
    visibilidade: 'PUBLICO',
    visivelPara: [autorId],
    curtidoPor: [],
    comentariosCount: 0,
    ambiente: 'DEMO',
    criadoEm: new Date(now.getTime() - index * 60 * 60 * 1000),
  },
}));

const amizadeUsuarioDemo = demoUserUid
  ? [{
      path: `amizades/${[demoUserUid, ids.admin].sort().join('_')}`,
      data: {
        solicitanteId: demoUserUid,
        destinatarioId: ids.admin,
        usuarios: [demoUserUid, ids.admin],
        status: 'ACEITO',
        criadoEm: now,
      },
    }]
  : [];

const documents = [
  ...usuarios,
  ...usuariosPublicos,
  ...estabelecimentos,
  ...quadras,
  ...partidas,
  ...membros,
  ...clubes,
  liga,
  ...ligaClubes,
  ...confrontos,
  ...clubeJogadores,
  ...goleiros,
  ...postagens,
  ...amizadeUsuarioDemo,
  configuracao,
];

const response = await fetch(
  `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:commit`,
  {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      writes: documents.map(({ path, data }) => ({
        update: {
          name: `${databaseRoot}/${path}`,
          fields: firestoreMap(data),
        },
      })),
    }),
  },
);

if (!response.ok) {
  throw new Error(`Firestore ${response.status}: ${await response.text()}`);
}

console.log(`${documents.length} documentos de demonstracao gravados em ${projectId}.`);

function daysFromNow(days) {
  return new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
}

function firestoreMap(object) {
  return Object.fromEntries(
    Object.entries(object).map(([key, value]) => [key, firestoreValue(value)]),
  );
}

function firestoreValue(value) {
  if (value === null) return { nullValue: null };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(firestoreValue) } };
  }
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (typeof value === 'object') {
    return { mapValue: { fields: firestoreMap(value) } };
  }
  return { stringValue: String(value) };
}
