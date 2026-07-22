// Configuração do Supabase para o painel administrativo.
// Substitua pelos valores do seu projeto em Project Settings > API.
const SUPABASE_URL = 'https://tcfmhvjymucwuckvzlca.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_6YKjzj4jEXeYKwQ7syxxGw_ShGf7pPw';

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Bloqueia o acesso a páginas internas do admin sem sessão válida.
async function requireAuth() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (!session) {
    window.location.href = 'index.html';
    return null;
  }
  return session;
}

// Usado na tela de login: se já houver sessão, pula direto para o dashboard.
async function redirectIfAuthed() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (session) {
    window.location.href = 'dashboard.html';
  }
}

async function logout() {
  await supabaseClient.auth.signOut();
  window.location.href = 'index.html';
}

function formatBRL(valor) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(valor) || 0);
}

function formatDate(dataStr) {
  if (!dataStr) return '-';
  return new Date(dataStr + 'T00:00:00').toLocaleDateString('pt-BR');
}
