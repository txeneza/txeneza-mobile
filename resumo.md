# Resumo das funcionalidades já implementadas — Txeneza Mobile

Este documento apresenta um levantamento funcional completo do estado atual da aplicação, **sem detalhes de código**.

## 1) Fluxo principal da aplicação

- **Inicialização inteligente**
  - Carrega variáveis de ambiente.
  - Decide a rota inicial com base em:
    - primeiro acesso (onboarding),
    - sessão ativa guardada localmente,
    - ausência de sessão (login).

- **Navegação por rotas**
  - Onboarding
  - Permissões
  - Login
  - Cadastro
  - Home (com abas internas)
  - Assistente IA
  - Perfil
  - Minhas ocorrências
  - Subpáginas de perfil (senha, privacidade, termos, FAQ, contato, reportar problema)

## 2) Onboarding e permissões

- **Onboarding em 4 telas**
  - Introdução ao propósito comunitário.
  - Reporte com foto e localização.
  - Operação offline.
  - Mapa e acompanhamento de impacto.

- **Gestão de permissões essenciais**
  - Câmara
  - Localização
  - Fluxo para nova tentativa e redirecionamento para configurações do dispositivo (quando necessário).
  - Ao conceder permissões, marca fim do primeiro acesso e leva ao login.

## 3) Autenticação (mock funcional)

- **Login**
  - Validação de email e palavra-passe.
  - Mensagens de sucesso/erro.
  - Redirecionamento para a home em caso de sucesso.

- **Cadastro**
  - Campos: nome completo, email, celular, palavra-passe e bairro.
  - Validações de formato e força mínima da palavra-passe.
  - Carregamento da lista de bairros da Beira.
  - Prevenção de emails duplicados.

- **Persistência local de utilizadores/sessão**
  - Sessão ativa guardada localmente.
  - Utilizadores mock guardados localmente.
  - Conta demo suportada.

## 4) Home e experiência principal

- **Estrutura por abas**
  - Início (mapa normal)
  - Mapa de calor
  - Assistente IA
  - Perfil

- **Barra superior personalizada**
  - Identidade visual da aplicação.
  - Indicador de conectividade com estado online/offline.

- **Ação principal “Denunciar”**
  - Botão flutuante dedicado.
  - Feedback imediato de envio online ou armazenamento offline para sincronização futura.

## 5) Mapa e ocorrências

- **Mapa interativo da cidade da Beira**
  - Modos de visualização:
    - normal,
    - satélite (suportado na base),
    - mapa de calor.
  - Integração com mapas via token de ambiente.

- **Ocorrências georreferenciadas**
  - Status: pendente, crítico, resolvido.
  - Visualização por marcadores individuais.
  - Agrupamento por clusters em níveis de zoom mais distantes.
  - Zoom animado ao interagir com clusters.

- **Mapa de calor**
  - Sobreposição de zonas críticas.
  - Legenda de intensidade (alta/média/baixa).

- **Localização do utilizador**
  - Botão de recentralização no mapa.
  - Animação de foco e feedback visual.

- **Conectividade e fallback de dados**
  - Monitoramento de rede em tempo real.
  - Troca entre conjunto completo de ocorrências (online) e subconjunto local (offline).
  - Alertas visuais e snackbars de estado da rede.

- **Painel de contexto no mapa**
  - Estado de sincronização.
  - Descrição contextual por modo (normal/calor).
  - Indicador de modo em tempo real vs dados locais.

## 6) Minhas ocorrências

- Visualização dedicada do histórico de reportes.
- Pesquisa textual por título/descrição.
- Filtros por status (todos, pendentes, críticos, resolvidos).
- Estado vazio amigável quando não há resultados.

## 7) Assistente IA (Xeni)

- **Chat conversacional**
  - Mensagem inicial contextual.
  - Chips de sugestões rápidas.
  - Indicador de digitação.
  - Histórico de mensagens com distinção utilizador/assistente.

- **Modo online**
  - Integração com serviço Gemini.
  - Suporte a fallback entre variantes de modelo.
  - Estratégia de repetição em indisponibilidade temporária.

- **Modo offline**
  - Respostas locais simuladas para continuidade do atendimento.
  - Mensagens contextualizadas para reciclagem, coleta e prazos.

- **Classificação de imagem (simulada)**
  - Modal para selecionar cenários de ocorrência.
  - Detecção de conectividade para decidir fluxo:
    - online: análise via IA remota,
    - offline: inferência local simulada (TensorFlow Lite).
  - Retorno estruturado com gravidade e recomendação de ação.

## 8) Perfil do utilizador

- **Carregamento de perfil com estados**
  - inicial, carregando, carregado, erro, atualizando.

- **Dados pessoais editáveis**
  - nome completo,
  - número de celular,
  - bairro.
  - Atualização persistida localmente (sessão e registo de utilizador).

- **Indicadores e gamificação**
  - total de denúncias,
  - resolvidas e pendentes,
  - pontos, nível e medalhas.

- **Acesso rápido**
  - Atalho para “Minhas Ocorrências”.

- **Configurações**
  - Tema (claro, escuro, sistema).
  - Idioma (opções pré-definidas).
  - Toggles de notificações push/email.
  - Toggle de sincronização offline.

- **Privacidade e segurança**
  - Alterar palavra-passe (fluxo de demonstração).
  - Toggles de permissões de localização e câmara.
  - Acesso à política de privacidade e termos.

- **Suporte**
  - FAQ
  - Reportar problema
  - Contato

- **Sessão**
  - Terminar sessão (limpa sessão local e volta para login).
  - Eliminar conta (mensagem informativa de indisponibilidade de backend).

## 9) Subpáginas de perfil e suporte

- **Alterar palavra-passe**
  - Formulário validado e feedback de sucesso (demonstração).

- **FAQ**
  - Perguntas frequentes sobre denúncia, status, gamificação e uso offline.

- **Reportar problema**
  - Formulário com categoria + descrição.
  - Feedback de submissão (demonstração).

- **Contato**
  - Email, telefone e endereço institucional.

- **Política de privacidade**
  - Conteúdo estruturado sobre dados, uso, partilha e direitos.

- **Termos de utilização**
  - Regras de uso, responsabilidades e alterações de termos.

## 10) Temas, UX e base transversal

- Sistema de temas claro/escuro com comutação em tempo real.
- Componentes visuais consistentes (tipografia, espaçamento, cores, raios).
- Layout responsivo e tratamento visual premium (efeitos de vidro, animações e transições).

## 11) Integrações e dependências funcionais já em uso

- Persistência local: preferências/sessão/dados mock.
- Conectividade: detecção online/offline.
- Mapas: tiles e renderização geográfica.
- IA remota: Gemini (chat e análise de imagem simulada).
- Permissões: câmara e localização.

## 12) Estado atual de módulos

- **Com implementação ativa e funcional visível:**
  - onboarding
  - auth
  - home
  - map
  - chatIA
  - profile

- **Estrutura criada, mas sem funcionalidades expostas neste estado:**
  - occurrence
  - sync

---

**Conclusão:** a aplicação já cobre um fluxo completo de ponta a ponta para onboarding, autenticação mock, navegação principal, mapeamento de ocorrências com suporte offline, assistência por IA (online/offline), gestão de perfil e páginas de suporte institucional.
