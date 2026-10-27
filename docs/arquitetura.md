# ConneMeet — arquitetura planejada

## Situação atual
- A aplicação publicada neste repositório é uma **demonstração front-end**, sem banco nem autenticação real.
- Interações são persistidas em `localStorage`, apenas no navegador.
- A migração SQL em `supabase/migrations` não foi executada.

## Etapas técnicas
1. Criar Supabase exclusivo para ConneMeet na organização expressamente autorizada.
2. Implantar e auditar PostgreSQL + Row Level Security (RLS), com testes entre contas diferentes.
3. Integrar cadastro e login, confirmação de idade 25+, perfis e preferências com consentimento.
4. Integrar publicações, reações, comentários, conexões, bloqueios, denúncias e mensagens privadas.
5. Implementar proteção antifraude, fluxo de moderação e exclusão de conta.
6. Implementar pagamento único somente no servidor e validar transações das lojas.
7. Testar usabilidade, acessibilidade, segurança e privacidade antes de disponibilização pública.

## Dados sensíveis
Não expor chaves secretas, documentos de identidade, dados íntimos, preferências religiosas nem informações de pagamento no cliente público. Serviços de produção exigem auditoria de LGPD.
