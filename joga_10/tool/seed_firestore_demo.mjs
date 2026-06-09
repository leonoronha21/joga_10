import { execFileSync } from 'node:child_process';

const projectId = process.env.FIREBASE_PROJECT_ID ?? 'joga10-ec65f';
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
  arena: 'estabelecimento-arena-paulista',
  ibirapuera: 'estabelecimento-ibirapuera',
  vila: 'estabelecimento-vila-madalena',
  society: 'quadra-society-principal',
  futsal: 'quadra-futsal',
  campo7: 'quadra-campo-7',
  basquete: 'quadra-basquete-coberto',
  areia: 'quadra-areia-premium',
  partida1: 'partida-sexta-demo',
  partida2: 'partida-campo7-demo',
  partida3: 'partida-finalizada-demo',
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
    cidade: 'Sao Paulo',
    role,
    ambiente: 'DEMO',
    ativo: true,
    criadoEm: now,
  },
}));

const estabelecimentos = [
  [ids.arena, 'Arena Joga10 Paulista', 'Bela Vista', 'Av. Paulista', '1000', -23.5614, -46.6559],
  [ids.ibirapuera, 'Centro Esportivo Ibirapuera', 'Moema', 'Av. Ibirapuera', '2100', -23.5988, -46.6629],
  [ids.vila, 'Quadras Vila Madalena', 'Vila Madalena', 'Rua Harmonia', '88', -23.5545, -46.6906],
].map(([id, nome, bairro, rua, numero, latitude, longitude]) => ({
  path: `estabelecimentos/${id}`,
  data: {
    nome,
    cidade: 'Sao Paulo',
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
      estabelecimentoNome: 'Arena Joga10 Paulista',
      quadraId: ids.society,
      quadraNome: 'Society Principal',
      dataHora: daysFromNow(3),
      duracao: '1h',
      status: 'AGENDADA',
      preco: 180,
      formato: '5x5',
      ambiente: 'DEMO',
    },
  },
  {
    path: `partidas/${ids.partida2}`,
    data: {
      organizadorId: ids.bruno,
      estabelecimentoId: ids.ibirapuera,
      estabelecimentoNome: 'Centro Esportivo Ibirapuera',
      quadraId: ids.campo7,
      quadraNome: 'Campo 7',
      dataHora: daysFromNow(9),
      duracao: '1h30',
      status: 'AGENDADA',
      preco: 210,
      formato: '7x7',
      ambiente: 'DEMO',
    },
  },
  {
    path: `partidas/${ids.partida3}`,
    data: {
      organizadorId: ids.admin,
      estabelecimentoId: ids.arena,
      estabelecimentoNome: 'Arena Joga10 Paulista',
      quadraId: ids.futsal,
      quadraNome: 'Quadra de Futsal',
      dataHora: daysFromNow(-5),
      duracao: '1h',
      status: 'FINALIZADA',
      preco: 140,
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

const documents = [
  ...usuarios,
  ...estabelecimentos,
  ...quadras,
  ...partidas,
  ...membros,
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
