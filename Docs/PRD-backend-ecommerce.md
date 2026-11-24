# PRD — API backend da SyntaxWear

**Status:** proposta de produto  
**Produto:** API para a loja virtual SyntaxWear  
**Versão:** 1.0  
**Idioma/moeda:** português do Brasil (pt-BR), BRL (R$)

## 1. Visão geral

Construir uma API backend para substituir os dados simulados do frontend e suportar a operação de uma loja online de calçados: consulta de catálogo, categorias, contas de clientes, carrinho, cálculo de entrega, pedidos e inscrição na newsletter. A API também deve fornecer operações administrativas protegidas para gerenciar produtos, categorias, clientes e pedidos.

O documento parte das telas e comportamentos encontrados no projeto atual. O frontend já apresenta páginas de início, listagem e detalhe de produto, navegação por categorias, cadastro/login, carrinho em drawer, consulta de CEP, newsletter, páginas institucionais e lojas. Parte dessas telas ainda usa mocks ou interações sem persistência.

## 2. Objetivos e resultados esperados

- Servir catálogo e categorias a partir do Supabase, sem depender de mocks locais.
- Persistir estoque e preços para evitar pedidos com valores ou quantidades inválidas.
- Permitir que clientes criem conta, mantenham endereços e acompanhem pedidos.
- Viabilizar um fluxo consistente do carrinho até a criação e atualização do pedido.
- Dar aos operadores endpoints administrativos para manter o catálogo e processar pedidos.
- Proteger dados pessoais e operações de escrita com autenticação, autorização e validação.

### Fora do escopo do MVP

- Painel administrativo (o backend disponibiliza endpoints; a interface administrativa não aparece nas telas atuais).
- Integração com um gateway específico de pagamento, transportadora, ERP ou emissão fiscal; os provedores ainda precisam ser escolhidos.
- Avaliações, favoritos, cupons, programa de fidelidade e recomendações personalizadas.
- CMS para editar banners, conteúdo institucional e unidades físicas. Esses conteúdos hoje são estáticos.

## 3. Usuários e permissões

| Perfil | Permissões principais |
|---|---|
| Visitante | Consultar produtos/categorias, calcular estimativa de frete, manter carrinho anônimo e cadastrar e-mail na newsletter. |
| Cliente autenticado | Ações de visitante, gerenciar os próprios dados e endereços, converter/consultar carrinho e consultar os próprios pedidos. |
| Administrador | CRUD administrativo de produtos e categorias, consultar/atualizar pedidos, consultar clientes e gerenciar estoque. |

As permissões devem ser aplicadas no backend. Um usuário nunca pode consultar ou alterar dados privados de outro cliente apenas por conhecer o identificador.

## 4. Requisitos funcionais

### RF-01 — Catálogo de produtos

- Listar e consultar produtos publicados, com paginação e ordenação.
- Filtrar por categoria e, quando disponíveis, por faixa de preço, cor, tamanho e disponibilidade.
- Retornar nome, slug, descrição, preço, imagens, cor e categoria; retornar também variantes/estoque quando aplicável.
- Permitir ao administrador criar, consultar, atualizar, publicar/despublicar e arquivar produtos.
- Validar que preços e quantidades sejam não negativos e que a categoria exista.
- Preservar os dados e referências de itens em pedidos antigos. Produto associado a pedidos não deve ser excluído fisicamente; deve ser arquivado.

**Campos sugeridos**

`id`, `name`, `slug`, `description`, `categoryId`, `basePrice`, `compareAtPrice` (opcional), `color`, `status` (`DRAFT`, `ACTIVE`, `ARCHIVED`), `images[]` (URL, texto alternativo, ordem), `createdAt`, `updatedAt`.

O frontend atual só expõe nome, imagem, preço, cor, descrição e categoria. Para uma loja de calçados, tamanho e estoque por tamanho são essenciais ao checkout mesmo que ainda não apareçam nas telas: modelar como variantes, por exemplo `sku`, `size`, `color`, `price` (se diferente), `stockQuantity` e `active`.

### RF-02 — Categorias

- Listar categorias ativas para a navegação e consultar categoria por slug.
- Filtrar/listar produtos da categoria.
- Permitir ao administrador criar, consultar, atualizar, ordenar, ativar/desativar e arquivar categorias.
- Campos sugeridos: `id`, `name`, `slug`, `description` (opcional), `imageUrl` (opcional, usado nos cards de categoria), `sortOrder`, `active`, timestamps.
- Slug deve ser único. Não remover fisicamente uma categoria referenciada por produtos; permitir desativação ou exigir reatribuição antes do arquivamento.

**Ponto de alinhamento:** o cabeçalho e o catálogo usam “Masculino”, “Feminino” e “Outlet”, enquanto os cards de categoria da home usam “casual”, “Esporte”, “Moderno” e “futurista”. O backend deve tratar categorias como dados configuráveis, sem codificar uma lista fixa. A equipe de produto deve confirmar se são taxonomias diferentes (público e estilo) antes de definir dados iniciais.

### RF-03 — Autenticação e usuários

- Cadastro com nome, sobrenome, e-mail, senha, CPF, data de nascimento e celular, conforme o formulário.
- Login, logout/renovação de sessão e recuperação de acesso.
- Suporte futuro ao botão de login Google que aparece na interface.
- Consultar e atualizar perfil próprio e endereços; administrador pode consultar clientes com acesso restrito.
- Validar unicidade de e-mail e CPF, formato de e-mail, CPF e telefone, data de nascimento e política de senha.
- Não retornar senha, hash, tokens ou dados de autenticação nas respostas.

**Campos sugeridos para o perfil de aplicação:** `id` (referência ao usuário de autenticação), `firstName`, `lastName`, `email`, `cpf`, `birthDate`, `cellphone`, `role`, `createdAt`, `updatedAt`. A senha e credenciais devem ser geridas pelo Supabase Auth, não persistidas pela aplicação via Prisma.

### RF-04 — Endereços

- CRUD de endereços do cliente, permitindo definir endereço padrão.
- Campos: `recipientName`, `label` (opcional), `cep`, `street/logradouro`, `number`, `complement`, `neighborhood`, `city`, `state/UF`, `country`, `isDefault`.
- Validar os campos obrigatórios e associar o endereço exclusivamente ao proprietário autenticado.
- O endereço usado em pedido deve ser copiado para um snapshot do pedido; mudanças futuras no cadastro não alteram compras anteriores.

### RF-05 — Carrinho

- Criar/consultar carrinho, adicionar variante, alterar quantidade e remover item.
- Permitir carrinho anônimo por identificador opaco; ao autenticar, mesclar com o carrinho da conta sem duplicar indevidamente as linhas.
- Retornar subtotal e linhas com preço atual, nome, imagem, variante/tamanho e disponibilidade.
- Validar disponibilidade e quantidade a cada alteração e novamente ao finalizar a compra.
- Preço enviado pelo cliente nunca é fonte de verdade; recalcular no backend.

### RF-06 — Frete por CEP

- Receber CEP e itens/variantes do carrinho e devolver endereço localizado, opções de entrega disponíveis, custo e prazo estimado, se houver.
- A tela atual consulta ViaCEP e calcula um valor fixo por região (Norte, Nordeste, Centro-Oeste, Sudeste, Sul). Essa regra pode servir apenas como estimativa inicial; deve ser configurável no backend e não tratada como cotação real de transportadora.
- Validar CEP, tratar CEP inexistente, falha do serviço externo e região sem regra sem produzir uma cotação falsa.
- Revalidar frete antes da criação do pedido. A cotação deve ter validade limitada e incluir um identificador/valores para o checkout.
- Na fase inicial, manter a consulta ViaCEP em serviço backend para não expor dependências nem concentrar regras no navegador. A escolha de provedor de frete real fica para etapa posterior.

### RF-07 — Pedidos

- Criar pedido a partir do carrinho e de um endereço/cotação válidos, usando preço, estoque e subtotal calculados no servidor.
- Registrar snapshot imutável dos itens (nome, SKU/variante, quantidade e preço unitário), endereço de entrega, frete, desconto, total e moeda.
- Reservar ou baixar estoque de forma transacional, impedindo venda acima do estoque disponível.
- Permitir ao cliente consultar somente os próprios pedidos e detalhes.
- Permitir ao administrador listar pedidos com filtros por estado, data e cliente e avançar/cancelar conforme regras de negócio.
- Não oferecer exclusão física de pedidos. Cancelamentos devem ser transições de estado auditáveis.
- Gerar código de pedido único e registrar datas de criação, pagamento e envio quando aplicável.

**Estados iniciais sugeridos:** `PENDING_PAYMENT`, `PAID`, `PROCESSING`, `SHIPPED`, `DELIVERED`, `CANCELLED`, `REFUNDED`. Definir transições permitidas (por exemplo, não permitir `DELIVERED` diretamente de `PENDING_PAYMENT`) e política de liberação/devolução do estoque em cancelamentos.

**Pagamento:** campos sugeridos no pedido incluem `paymentProvider`, `paymentReference`, `paymentStatus`, `paidAt`; nunca armazenar número completo do cartão, CVV ou credenciais de pagamento. Sem provedor definido, o MVP pode criar pedidos pendentes e deixar confirmação/estorno por integração ou operação administrativa controlada.

### RF-08 — Preço promocional e parcelamento

A tela de produto apresenta desconto de 10% no Pix e parcelamento em 6 vezes, atualmente calculados apenas no frontend. Se essas condições forem válidas comercialmente, devem ser retornadas/calculadas pela API com regras configuráveis, por exemplo `pixDiscountPercentage`, número máximo de parcelas e elegibilidade. O valor final, desconto e forma escolhida devem ser persistidos no pedido. Não assumir que preço promocional está ativo até confirmação comercial.

### RF-09 — Newsletter

- Inscrever e-mail a partir do formulário do rodapé.
- Validar e-mail, normalizar e evitar inscrições duplicadas.
- Registrar consentimento e data/hora da inscrição; disponibilizar cancelamento da inscrição.
- Proteger o endpoint contra abuso (rate limiting e validação).

### RF-10 — Home e conteúdo institucional

A home reúne destaque, cards de categorias e galeria. A API deve fornecer categorias e produtos ativos necessários para o catálogo; banners, texto “Sobre” e conteúdo de lojas podem permanecer estáticos no MVP. Se houver necessidade de edição administrativa, criar recurso de conteúdo/lojas em fase posterior, em vez de acoplar esses dados ao produto.

## 5. Recursos e modelo de dados inicial

Modelo lógico indicado para Prisma (nomes físicos e estratégia de IDs podem ser definidos na implementação):

- `UserProfile` — perfil e papel no sistema; identidade vinculada ao Supabase Auth.
- `Address` — endereços do usuário.
- `Category` — categoria navegável e seu slug.
- `Product` — dados gerais do calçado.
- `ProductImage` — imagens ordenadas do produto.
- `ProductVariant` — SKU/tamanho/cor, preço opcional e estoque.
- `Cart` e `CartItem` — carrinho de visitante ou de cliente e suas variantes/quantidades.
- `ShippingQuote` — CEP, modalidade, preço, prazo, validade e origem da estimativa.
- `Order` e `OrderItem` — totais/estado e snapshot das linhas.
- `NewsletterSubscription` — e-mail, consentimento, estado e datas.
- `InventoryMovement` (recomendado) — auditoria de entradas, reservas, baixas e devoluções de estoque.

Usar valores monetários em centavos inteiros (`priceCents`, `subtotalCents`, `shippingCents`, `totalCents`) ou tipo decimal apropriado com precisão fixa; nunca usar ponto flutuante binário para cálculo monetário. Definir índices e restrições únicas para e-mail, CPF, slug, SKU e código do pedido, respeitando a política de armazenamento de dados pessoais.

## 6. API proposta

Prefixo `/api/v1`; JSON em camelCase; documentação OpenAPI; erros padronizados com `code`, `message` e, quando seguro, `details`. Listagens devem ter paginação limitada, filtros documentados e ordenação permitida.

| Método e rota | Acesso | Objetivo |
|---|---|---|
| `GET /products` | público | Listar e filtrar catálogo |
| `GET /products/:idOrSlug` | público | Detalhe do produto, variantes e imagens |
| `POST /admin/products` | admin | Criar produto |
| `PATCH /admin/products/:id` | admin | Atualizar produto |
| `DELETE /admin/products/:id` | admin | Arquivar produto, sem apagar histórico |
| `GET /categories` | público | Listar categorias ativas |
| `GET /categories/:slug/products` | público | Listar produtos da categoria |
| `POST /admin/categories` | admin | Criar categoria |
| `PATCH /admin/categories/:id` | admin | Atualizar categoria |
| `DELETE /admin/categories/:id` | admin | Desativar/arquivar categoria |
| `POST /auth/register` | público | Criar conta via fluxo Supabase Auth e perfil |
| `POST /auth/login` | público | Autenticar e obter sessão/JWT |
| `GET /users/me` | cliente | Consultar perfil próprio |
| `PATCH /users/me` | cliente | Atualizar perfil próprio |
| `GET/POST /users/me/addresses` | cliente | Consultar/criar endereços próprios |
| `PATCH/DELETE /users/me/addresses/:id` | cliente | Atualizar/remover endereço próprio |
| `GET/POST /cart` | público/cliente | Consultar carrinho e adicionar item |
| `PATCH /cart/items/:id` | público/cliente | Alterar quantidade |
| `DELETE /cart/items/:id` | público/cliente | Remover linha |
| `POST /shipping/quotes` | público | Consultar CEP e cotar entrega |
| `POST /orders` | cliente | Finalizar carrinho e criar pedido |
| `GET /orders` | cliente | Listar pedidos próprios |
| `GET /orders/:id` | cliente | Consultar pedido próprio |
| `GET /admin/orders` | admin | Consultar pedidos e filtrar |
| `PATCH /admin/orders/:id/status` | admin | Aplicar transição permitida |
| `GET /admin/users` | admin | Listar clientes com paginação e filtros restritos |
| `POST /newsletter/subscriptions` | público | Inscrever e-mail |
| `DELETE /newsletter/subscriptions` | público | Cancelar inscrição com token ou mecanismo equivalente |

As rotas de escrita administrativa de variantes/estoque devem ser incluídas na implementação do catálogo, mesmo que não estejam separadas na tabela. Operações de pagamento e webhooks devem ser adicionados somente após escolher um provedor, com validação de assinatura e idempotência.

## 7. Fluxos principais

### Navegação e catálogo

1. Frontend carrega categorias ativas e produtos destacados.
2. Visitante abre listagem/categoria com paginação e filtros.
3. Ao abrir o detalhe, consulta preço, imagens e variantes/estoque.

### Compra

1. Visitante adiciona uma variante/tamanho ao carrinho.
2. Backend confirma disponibilidade e retorna o total calculado.
3. Cliente informa CEP; backend retorna endereço e cotação de frete.
4. Cliente autentica ou cria conta, seleciona endereço e forma de pagamento suportada.
5. Backend valida novamente carrinho, estoque, cotação e totais; cria pedido transacionalmente com snapshots.
6. Pedido permanece pendente até confirmação do pagamento. Atualizações posteriores são idempotentes e auditáveis.

### Gestão administrativa

1. Administrador autenticado cria/atualiza produto, categoria, variante e estoque.
2. Mudanças de preço/estoque não alteram snapshots de pedidos existentes.
3. Operador consulta pedido e aplica apenas transições de estado autorizadas.

## 8. Requisitos não funcionais e técnicos

- **Runtime/API:** Node.js + Fastify + TypeScript.
- **Dados:** Supabase Postgres como banco; Prisma como ORM, schema e migrações.
- **Autenticação:** Supabase Auth como provedor recomendado para identidade e JWT; Fastify valida assinatura/audiência/expiração do token. Não confiar apenas em dados do payload não verificados.
- **Testes:** Vitest para testes unitários, integração e regras de negócio; usar banco de teste isolado para integração.
- **Validação:** schemas de request/response (padrão Fastify ou Zod) e tipos coerentes entre validação e domínio.
- **Segurança:** TLS em produção, CORS restrito às origens do frontend, rate limit em autenticação/CEP/newsletter, proteção contra enumeração de contas, gestão de secrets por ambiente, autorização por papel e propriedade do recurso.
- **Privacidade:** coletar apenas dados necessários; proteger CPF e dados pessoais em trânsito e repouso; limitar acesso administrativo e logs; definir retenção, consentimento e atendimento a solicitações conforme LGPD.
- **Resiliência:** timeout para dependências externas; erros explícitos; não registrar tokens, senhas, CPF completo ou dados financeiros sensíveis.
- **Consistência:** transações de banco para pedido/estoque e idempotency key em operações de finalização e callbacks de pagamento.
- **Operação:** health check, logs estruturados com request ID, monitoramento de erros e métricas sem dados pessoais desnecessários.
- **Mídia:** persistir referências/URLs de imagens; avaliar Supabase Storage para upload administrativo com política de acesso. Não depender de import de arquivos locais do frontend como URL permanente.

## 9. Critérios de aceite do MVP

1. Produtos e categorias retornados pela API substituem os mocks nas listagens, cards, detalhe e filtros por categoria.
2. Administrador consegue criar/editar/arquivar produtos e categorias; slugs/SKUs duplicados são rejeitados com erro validável.
3. Cliente consegue se cadastrar, autenticar, consultar/editar perfil e gerenciar endereços sem acessar conta alheia.
4. Carrinho permite adicionar, atualizar e remover variantes; valores são recalculados no backend.
5. CEP inválido, serviço de CEP indisponível e regra regional ausente retornam erros claros sem cotação inventada.
6. Pedido registra snapshots, valores em BRL e endereço, e não permite quantidade acima do estoque nem duplicar a finalização mediante repetição idempotente.
7. Cliente consulta apenas os seus pedidos; administrador pode filtrar pedidos e aplicar somente transições válidas.
8. Newsletter aceita e-mail válido, trata duplicidade e permite descadastro.
9. Endpoints de leitura e escrita têm schemas documentados, autenticação/autorização conforme a matriz e testes Vitest.
10. Build TypeScript, lint e testes definidos para o backend passam em CI.

## 10. Estratégia de entrega

1. **Fundação:** projeto Fastify/TypeScript, configuração por ambiente, Supabase, Prisma, migrações, validação, logs, OpenAPI e testes.
2. **Catálogo:** categorias, produtos, imagens, variantes/estoque, endpoints públicos e operações administrativas.
3. **Conta:** Supabase Auth/JWT, perfil, autorização e endereços.
4. **Carrinho e entrega:** carrinho anônimo/autenticado, mesclagem, integração ViaCEP e regra inicial configurável de frete.
5. **Pedidos:** criação transacional, snapshots, estoque, estados, consulta de cliente/admin e idempotência.
6. **Complementos:** newsletter, integração de pagamento/frete real e conteúdo administrável conforme prioridade comercial.

## 11. Decisões pendentes

- Confirmar taxonomia de categorias: público (“Masculino/Feminino”) versus estilo (“casual/Esporte/Moderno/futurista”).
- Definir tamanhos, grade, disponibilidade por variante e política de reserva/baixa de estoque.
- Confirmar preço promocional de Pix, parcelamento e se ambos serão configuráveis por produto ou globalmente.
- Escolher provedor de pagamentos, política de cancelamento/reembolso e provedor de frete.
- Definir prazo de retenção e fluxos para exclusão/anonimização de dados pessoais conforme LGPD.
- Decidir se conteúdo de banners, lojas e páginas institucionais precisa ser editável no painel.
