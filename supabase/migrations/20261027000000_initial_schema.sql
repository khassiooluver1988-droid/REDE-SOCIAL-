-- ConneMeet v0.1 — esquema inicial PROPOSTO. Ainda não executado em Supabase.
-- Apenas adultos 25+; age é declaratória no MVP. Verificação de idade exigida antes do lançamento.
-- Operações financeiras/verification_status são alteradas SOMENTE por servidor autorizado.
begin;

create schema if not exists private;

create table if not exists public.account_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state text not null default 'pending' check (state in ('pending','active','revoked','refunded')),
  payment_provider text,
  external_payment_reference text unique,
  activated_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) between 2 and 60),
  declared_age smallint not null check (declared_age between 25 and 110),
  city text not null default 'Brasil' check (char_length(city) <= 90),
  region_code varchar(2),
  bio text not null default '' check (char_length(bio) <= 1200),
  intent text not null default 'conhecer' check (intent in ('conhecer','amizade','namoro','serio','casual')),
  interests text[] not null default '{}',
  avatar_path text,
  visibility text not null default 'visible' check (visibility in ('visible','hidden')),
  verification_status text not null default 'unverified' check (verification_status in ('unverified','pending','verified')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(blocker_id,blocked_id),
  constraint different_people_blocks check (blocker_id <> blocked_id)
);

create table if not exists public.connection_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  state text not null default 'pending' check (state in ('pending','accepted','declined')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(sender_id, receiver_id),
  constraint different_people_requests check(sender_id <> receiver_id)
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(trim(content)) between 1 and 1500),
  category text not null default 'momentos' check(category in ('momentos','amizades','meu_canto')),
  visibility text not null default 'public' check(visibility in ('public','connections','private')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists posts_recent on public.posts(created_at desc);
create index if not exists posts_author_recent on public.posts(author_id,created_at desc);

create table if not exists public.post_reactions (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(post_id,user_id)
);
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check(char_length(trim(content)) between 1 and 500),
  created_at timestamptz not null default now()
);
create index if not exists comments_post_created on public.comments(post_id,created_at);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles(id) on delete cascade,
  user_b uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  check(user_a <> user_b)
);
create unique index if not exists conversations_pair_unique on public.conversations (least(user_a,user_b),greatest(user_a,user_b));

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index if not exists messages_conversation_created on public.messages(conversation_id,created_at desc);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_user_id uuid references public.profiles(id) on delete set null,
  target_post_id uuid references public.posts(id) on delete set null,
  category text not null check(category in ('assedio','golpe','perfil_falso','spam','conteudo','outro')),
  details text not null default '' check (char_length(details) <= 1500),
  state text not null default 'open' check(state in ('open','reviewing','closed')),
  created_at timestamptz not null default now()
);

-- Auxiliar do backend: não confiar em metadata editável do usuário para autorização.
-- Definer é necessário para consultar direito à ativação sem expor transações de terceiros.
create or replace function private.has_active_access()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (
  select 1 from public.account_entitlements a
  where a.user_id = (select auth.uid()) and a.state='active'
); $$;
revoke all on function private.has_active_access() from public, anon;
-- Verifica bloqueios nos dois sentidos sem expor a quem bloqueou o usuário.
create or replace function private.is_blocked_pair(a uuid,b uuid)
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.blocks x where
  (x.blocker_id=a and x.blocked_id=b) or (x.blocker_id=b and x.blocked_id=a)); $$;
revoke all on function private.is_blocked_pair(uuid,uuid) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.has_active_access() to authenticated;
grant execute on function private.is_blocked_pair(uuid,uuid) to authenticated;

-- RLS em TODAS as tabelas públicas.
alter table public.account_entitlements enable row level security;
alter table public.profiles enable row level security;
alter table public.blocks enable row level security;
alter table public.connection_requests enable row level security;
alter table public.posts enable row level security;
alter table public.post_reactions enable row level security;
alter table public.comments enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.reports enable row level security;

-- Revogar permissões amplas herdadas e liberar operações estritamente necessárias.
revoke all on public.account_entitlements,public.profiles,public.blocks,public.connection_requests,
public.posts,public.post_reactions,public.comments,public.conversations,public.messages,public.reports
from anon,authenticated;

grant select on public.account_entitlements to authenticated;
create policy "entitlement_read_own" on public.account_entitlements for select to authenticated
using(user_id=(select auth.uid()));

-- Perfil pode ser criado antes do pagamento. Outros perfis só são visíveis a contas ativadas.
grant select on public.profiles to authenticated;
grant insert(id,display_name,declared_age,city,region_code,bio,intent,interests,avatar_path,visibility) on public.profiles to authenticated;
grant update(display_name,declared_age,city,region_code,bio,intent,interests,avatar_path,visibility) on public.profiles to authenticated;
create policy "profiles_read_active_or_self" on public.profiles for select to authenticated
using (id=(select auth.uid()) or (
  private.has_active_access() and visibility='visible'
  and not private.is_blocked_pair((select auth.uid()),profiles.id)
));
create policy "profiles_insert_self" on public.profiles for insert to authenticated
with check(id=(select auth.uid()) and verification_status='unverified');
create policy "profiles_update_self" on public.profiles for update to authenticated
using(id=(select auth.uid())) with check(id=(select auth.uid()));

-- BLOQUEIOS: visíveis apenas ao autor; não permitir edição de pares.
grant select,insert,delete on public.blocks to authenticated;
create policy "blocks_read_self" on public.blocks for select to authenticated using(blocker_id=(select auth.uid()));
create policy "blocks_add_self" on public.blocks for insert to authenticated with check(blocker_id=(select auth.uid()));
create policy "blocks_delete_self" on public.blocks for delete to authenticated using(blocker_id=(select auth.uid()));

-- Pedido de conexão: somente participantes; aceitação apenas pelo receptor.
grant select,insert on public.connection_requests to authenticated;
grant update(state) on public.connection_requests to authenticated;
create policy "requests_read_party" on public.connection_requests for select to authenticated
using(private.has_active_access() and (sender_id=(select auth.uid()) or receiver_id=(select auth.uid())));
create policy "requests_send" on public.connection_requests for insert to authenticated
with check(private.has_active_access() and sender_id=(select auth.uid()) and state='pending'
 and not private.is_blocked_pair(sender_id,receiver_id));
create policy "requests_receiver_decides" on public.connection_requests for update to authenticated
using(private.has_active_access() and receiver_id=(select auth.uid()) and state='pending')
with check(private.has_active_access() and receiver_id=(select auth.uid()) and state in ('accepted','declined'));

-- FEED: somente contas ativadas veem posts públicos, próprios e de conexões aceitas.
grant select,insert,delete on public.posts to authenticated;
grant update(content,category,visibility) on public.posts to authenticated;
create policy "posts_read_allowed" on public.posts for select to authenticated
using(private.has_active_access() and (
 author_id=(select auth.uid()) or
 (visibility='public' and not private.is_blocked_pair((select auth.uid()),author_id)) or
 (visibility='connections' and exists(
  select 1 from public.connection_requests cr
  where cr.state='accepted' and
  ((cr.sender_id=(select auth.uid()) and cr.receiver_id=author_id) or
   (cr.receiver_id=(select auth.uid()) and cr.sender_id=author_id))
 ))));
create policy "posts_create_self" on public.posts for insert to authenticated
with check(private.has_active_access() and author_id=(select auth.uid()));
create policy "posts_update_self" on public.posts for update to authenticated
using(private.has_active_access() and author_id=(select auth.uid()))
with check(private.has_active_access() and author_id=(select auth.uid()));
create policy "posts_delete_self" on public.posts for delete to authenticated
using(author_id=(select auth.uid()));

-- Comentários e reações herdando a visibilidade do post por RLS.
grant select,insert,delete on public.post_reactions to authenticated;
create policy "reactions_read_allowed" on public.post_reactions for select to authenticated
using(private.has_active_access() and exists(select 1 from public.posts p where p.id=post_id));
create policy "reactions_add_own" on public.post_reactions for insert to authenticated
with check(private.has_active_access() and user_id=(select auth.uid()) and exists(select 1 from public.posts p where p.id=post_id));
create policy "reactions_remove_own" on public.post_reactions for delete to authenticated
using(user_id=(select auth.uid()));
grant select,insert,delete on public.comments to authenticated;
create policy "comments_read_allowed" on public.comments for select to authenticated
using(private.has_active_access() and exists(select 1 from public.posts p where p.id=post_id));
create policy "comments_add_own" on public.comments for insert to authenticated
with check(private.has_active_access() and author_id=(select auth.uid()) and exists(select 1 from public.posts p where p.id=post_id));
create policy "comments_remove_own" on public.comments for delete to authenticated
using(author_id=(select auth.uid()));

-- Chat: somente membros de uma conexão aceita e não bloqueada.
grant select,insert on public.conversations to authenticated;
create policy "conversations_read_member" on public.conversations for select to authenticated
using(private.has_active_access() and (user_a=(select auth.uid()) or user_b=(select auth.uid())));
create policy "conversations_insert_connected" on public.conversations for insert to authenticated
with check(private.has_active_access() and user_a=(select auth.uid())
 and exists(select 1 from public.connection_requests cr where cr.state='accepted' and
 ((cr.sender_id=user_a and cr.receiver_id=user_b) or (cr.sender_id=user_b and cr.receiver_id=user_a)))
 and not private.is_blocked_pair(user_a,user_b));

grant select,insert on public.messages to authenticated;
create policy "messages_read_member" on public.messages for select to authenticated
using(private.has_active_access() and exists(
 select 1 from public.conversations c
 where c.id=conversation_id and (c.user_a=(select auth.uid()) or c.user_b=(select auth.uid()))
));
create policy "messages_send_member" on public.messages for insert to authenticated
with check(private.has_active_access() and sender_id=(select auth.uid()) and exists(
 select 1 from public.conversations c
 where c.id=conversation_id and (c.user_a=(select auth.uid()) or c.user_b=(select auth.uid()))
 and not private.is_blocked_pair(c.user_a,c.user_b)
));

-- Denúncias: apenas autor e servidores administrativos podem consultar.
grant select on public.reports to authenticated;
grant insert(reporter_id,reported_user_id,target_post_id,category,details) on public.reports to authenticated;
create policy "reports_read_own" on public.reports for select to authenticated
using(reporter_id=(select auth.uid()));
create policy "reports_create_own" on public.reports for insert to authenticated
with check(reporter_id=(select auth.uid()));

commit;