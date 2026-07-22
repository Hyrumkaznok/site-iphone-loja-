-- Schema do painel administrativo (clientes, vendas e financeiro)
-- Rode este script no SQL Editor do seu projeto Supabase.

create extension if not exists "pgcrypto";

-- CLIENTES
create table if not exists clientes (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  telefone text,
  whatsapp text,
  email text,
  observacoes text,
  created_at timestamptz not null default now()
);

-- VENDAS (Celulares Comprados)
create table if not exists vendas (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references clientes(id) on delete cascade,
  modelo text not null,
  marca text not null,
  cor text,
  armazenamento text,
  imei text,
  valor numeric(10,2) not null default 0,
  forma_pagamento text,
  data_venda date not null default current_date,
  garantia text,
  observacoes text,
  created_at timestamptz not null default now()
);

-- FINANCEIRO
create table if not exists financeiro (
  id uuid primary key default gen_random_uuid(),
  tipo text not null check (tipo in ('entrada', 'saida')),
  descricao text not null,
  valor numeric(10,2) not null default 0,
  data date not null default current_date,
  venda_id uuid references vendas(id) on delete set null,
  cliente_id uuid references clientes(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Ao registrar uma venda, gera automaticamente o lançamento financeiro correspondente.
create or replace function public.registrar_financeiro_venda()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  nome_cliente text;
begin
  select nome into nome_cliente from clientes where id = new.cliente_id;

  insert into financeiro (tipo, descricao, valor, data, venda_id, cliente_id)
  values (
    'entrada',
    'Venda - ' || new.marca || ' ' || new.modelo || ' - ' || coalesce(nome_cliente, 'Cliente'),
    new.valor,
    new.data_venda,
    new.id,
    new.cliente_id
  );

  return new;
end;
$$;

drop trigger if exists trg_venda_financeiro on vendas;
create trigger trg_venda_financeiro
  after insert on vendas
  for each row
  execute function public.registrar_financeiro_venda();

-- ROW LEVEL SECURITY
-- Apenas usuários autenticados (criados manualmente em Authentication > Users)
-- podem ler/escrever. Não há cadastro público.
alter table clientes enable row level security;
alter table vendas enable row level security;
alter table financeiro enable row level security;

create policy "Autenticados podem tudo em clientes"
  on clientes for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

create policy "Autenticados podem tudo em vendas"
  on vendas for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

create policy "Autenticados podem tudo em financeiro"
  on financeiro for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');
