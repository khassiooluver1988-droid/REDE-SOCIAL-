# REDE-SOCIAL- — ConneMeet

**ConneMeet** é um projeto de rede social brasileira para adultos (25+), voltado a namoro, amizades, afinidades e comunidades.

> **Status: protótipo demonstrativo.** O código está no GitHub, mas ainda não há usuários reais, backend ativo, login, pagamento ou chat multiusuário. Não inserir dados pessoais reais neste protótipo.

## O que já existe

- Página inicial com **Momentos** e feed demonstrativo.
- **Publicar**, **Gostei**, **Responder**, **Enviar** (simulado), **Salvar**, **Seguir**.
- **Sintonia** com intenções de namoro, amizades e afinidades.
- **Conversas** ilustrativas e página de **Grupos**.
- **Perfil** com **Sobre mim**, **Hoje**, **Meu canto**, **Fotos**, **Álbuns** e **Clipes**.
- Layout responsivo para celulares e desktop.
- Interações demonstrativas salvas somente no `localStorage` do navegador.
- Migração SQL **proposta** em `supabase/migrations/20261027000000_initial_schema.sql`.

### Para abrir localmente

```bash
python3 -m http.server 8080
```

Abra `http://localhost:8080` no navegador.

### Publicar uma prévia no GitHub Pages

Como o repositório é público, uma prévia de demonstração pode ser habilitada pelo proprietário em **Settings → Pages → Deploy from a branch → main → /(root)**. GitHub Pages hospeda apenas esta interface estática. Ele **não** implementa banco de dados, pagamentos nem autenticação.

## Supabase — ainda não conectado

O SQL disponibilizado é uma **especificação de banco** e precisa de revisão, aplicação num projeto próprio e validação rigorosa das regras RLS antes de qualquer uso com dados pessoais.

Etapas pendentes: escolher organização Supabase, criar projeto, ativar autenticação, testar políticas de acesso, integrar posts/chat/storage, fluxos de denúncia, prevenção de fraude, verificação etária e pagamento único com confirmação por servidor. **Nunca disponibilizar chaves secretas no repositório.**

## Arquivos principais

```text
index.html
styles.css
app.js
assets/favicon.svg
supabase/migrations/20261027000000_initial_schema.sql
docs/arquitetura.md
docs/diagramas.md
docs/checklist.md
.env.example
.gitignore
```

**Escopo comercial:** pagamento único de ativação (ainda não implementado), sem mensalidade. Não cobrar usuários neste protótipo.

**Metodologia:** ASD-STE100-002-2026-ANEXAR-SEMPRE — TEXTO → DIAGRAMA → CHECKLIST.
