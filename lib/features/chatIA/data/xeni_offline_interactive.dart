/// Gerenciador de árvore de conversa interativa e contínua para a assistente Xeni no modo offline.
///
/// Permite um fluxo longo e ramificado de conversação com sub-opções e navegação,
/// bem como respostas de fallback limpas em caso de falha de rede.
class XeniOfflineOption {
  final String id;
  final String label;
  final String responseText;
  final List<XeniOfflineOption>? followUpOptions;

  const XeniOfflineOption({
    required this.id,
    required this.label,
    required this.responseText,
    this.followUpOptions,
  });
}

class XeniOfflineInteractive {
  XeniOfflineInteractive._();

  // --- SUB-OPÇÕES REUTILIZÁVEIS E DE VOLTAR ---
  static const XeniOfflineOption _optVoltarMenu = XeniOfflineOption(
    id: 'voltar_menu',
    label: 'Voltar ao Menu Principal',
    responseText: 'Modo Offline - Menu Principal\n\n'
        'Em que outro tópico de saneamento e reciclagem na Cidade da Beira posso ajudar?',
  );

  // --- ÁRVORE DE CONVERSAÇÃO COMPLETA E EXTENSA ---

  // 1. RAMO: RECICLAGEM E SEPARAÇÃO
  static const List<XeniOfflineOption> _subReciclagem = [
    XeniOfflineOption(
      id: 'recicla_plastico',
      label: 'Plástico e Metais',
      responseText: 'Modo Offline - Plásticos e Metais\n\n'
          'Os plásticos e metais devem ser colocados no Ecoponto Amarelo:\n\n'
          '- Garrafas PET, embalagens de champô e detergente limpas.\n'
          '- Latas de alumínio de bebidas e conservas alimentares.\n'
          '- Sacos plásticos e película aderente limpos.\n\n'
          'Recomendação: Retire o excesso de líquido ou comida antes de depositar no ecoponto.',
    ),
    XeniOfflineOption(
      id: 'recicla_papel',
      label: 'Papel e Cartão',
      responseText: 'Modo Offline - Papel e Cartão\n\n'
          'O papel e cartão devem ser colocados no Ecoponto Azul:\n\n'
          '- Caixas de papelão desdobradas e secas.\n'
          '- Jornais, revistas, cadernos e embalagens de papelão.\n\n'
          'Atenção: Papel engordurado (como caixas de pizza com óleo) ou papéis higiénicos não devem ir para reciclagem.',
    ),
    XeniOfflineOption(
      id: 'recicla_vidro',
      label: 'Vidro e Frascos',
      responseText: 'Modo Offline - Vidro\n\n'
          'O vidro deve ser colocado no Ecoponto Verde:\n\n'
          '- Garrafas de vidro de sumo, refrigerante e vinho.\n'
          '- Frascos de conservas e doces inteiros.\n\n'
          'Atenção: Espelhos, lâmpadas e vidros de janelas partidos não devem ser misturados no ecoponto verde.',
    ),
    XeniOfflineOption(
      id: 'recicla_organico',
      label: 'Resíduos Orgânicos',
      responseText: 'Modo Offline - Orgânicos\n\n'
          'Os resíduos orgânicos compreendem restos de alimentos, cascas de fruta e restos de jardinagem.\n\n'
          '- Devem ser acondicionados em sacos bem vedados.\n'
          '- Depositar nos contentores comunitários de lixo doméstico.\n'
          '- Podem também ser utilizados para compostagem doméstica em hortas residenciais.',
    ),
    _optVoltarMenu,
  ];

  // 2. RAMO: LOCALIZAÇÃO DE ECOPONTOS
  static const List<XeniOfflineOption> _subEcopontos = [
    XeniOfflineOption(
      id: 'eco_ponta_gea',
      label: 'Ponta Gêa e Chaimite',
      responseText: 'Modo Offline - Bairros Ponta Gêa e Chaimite\n\n'
          'Nesta zona existem ecopontos triplos instalados perto da zona costeira e das avenidas principais.\n\n'
          'São ideais para deposição seletiva de embalagens de plástico, latas e garrafas de vidro.',
    ),
    XeniOfflineOption(
      id: 'eco_munhava',
      label: 'Munhava e Esturro',
      responseText: 'Modo Offline - Bairros Munhava e Esturro\n\n'
          'Em bairros de maior densidade populacional como Munhava e Esturro, o Município disponibiliza contentores comunitários de grande capacidade (7 a 12 metros cúbicos).\n\n'
          'A recolha nestes pontos é realizada diariamente no período matinal e ao final da tarde.',
    ),
    XeniOfflineOption(
      id: 'eco_manga',
      label: 'Manga e Macuti',
      responseText: 'Modo Offline - Bairros Manga e Macuti\n\n'
          'Na Manga e no Macuti existem pontos de recolha estratégicos junto a mercados e feiras de bairro.\n\n'
          'Pode abrir o mapa interativo no separador Início da app para navegar até ao ecoponto mais próximo.',
    ),
    _optVoltarMenu,
  ];

  // 3. RAMO: COMO DENUNCIAR
  static const List<XeniOfflineOption> _subDenuncia = [
    XeniOfflineOption(
      id: 'denuncia_passos',
      label: 'Passo a passo na câmara',
      responseText: 'Modo Offline - Passo a Passo\n\n'
          '1. Abra o botão central da câmara na barra inferior.\n'
          '2. Tire uma foto nítida focando no monte de lixo.\n'
          '3. O GPS deteta a localização exata automaticamente.\n'
          '4. Selecione a gravidade e confirme o envio.',
    ),
    XeniOfflineOption(
      id: 'denuncia_offline',
      label: 'Fila de espera offline',
      responseText: 'Modo Offline - Fila de Espera\n\n'
          'Se submeter uma denúncia sem internet:\n\n'
          '- A denúncia é gravada no armazenamento interno do telemóvel.\n'
          '- Assim que a ligação for restabelecida, a app envia os dados ao servidor sem que precise de repetir o processo!',
    ),
    XeniOfflineOption(
      id: 'denuncia_categorias',
      label: 'Categorias de lixo',
      responseText: 'Modo Offline - Categorias\n\n'
          'Categorias disponíveis para denúncias:\n'
          '- Lixo Doméstico Acumulado\n'
          '- Entulho e Materiais de Construção\n'
          '- Resíduos Hospitalares ou Perigosos\n'
          '- Vias Públicas ou Valetas Obstruídas\n'
          '- Carcaças e Resíduos Metálicos',
    ),
    _optVoltarMenu,
  ];

  // 4. RAMO: PRAZOS E ACOMPANHAMENTO
  static const List<XeniOfflineOption> _subPrazos = [
    XeniOfflineOption(
      id: 'prazo_avaliacao',
      label: 'Prazo de avaliação 24h-48h',
      responseText: 'Modo Offline - Prazo de Avaliação\n\n'
          'A equipa municipal analisa as novas denúncias no prazo de 24 a 48 horas úteis.\n\n'
          'Caso haja urgência ou risco sanitário elevado (gravidade crítica), a equipa de intervenção rápida é acionada prioritariamente.',
    ),
    XeniOfflineOption(
      id: 'prazo_validacao',
      label: 'Validação pelo morador',
      responseText: 'Modo Offline - Validação pelo Morador\n\n'
          'Quando o município conclui a limpeza do local:\n\n'
          '1. O estado da denúncia muda para Resolvida.\n'
          '2. O morador recebe uma notificação na app.\n'
          '3. É aberta uma tela de verificação onde o morador compara a foto inicial com a foto de resolução enviada pela equipa.',
    ),
    _optVoltarMenu,
  ];

  // 5. RAMO: HORÁRIOS DE RECOLHA
  static const List<XeniOfflineOption> _subHorarios = [
    XeniOfflineOption(
      id: 'horario_manha',
      label: 'Turno da Manhã (6h-10h)',
      responseText: 'Modo Offline - Turno da Manhã\n\n'
          'Atende prioritariamente o centro da cidade, feiras, zonas comerciais e vias de grande tráfego.',
    ),
    XeniOfflineOption(
      id: 'horario_noite',
      label: 'Turno da Tarde/Noite (17h-21h)',
      responseText: 'Modo Offline - Turno da Noite\n\n'
          'Atende zonas residenciais e bairros periféricos para desocupação dos contentores comunitários antes da madrugada.',
    ),
    _optVoltarMenu,
  ];

  // 6. RAMO: ENTULHO DE OBRAS
  static const List<XeniOfflineOption> _subEntulho = [
    XeniOfflineOption(
      id: 'entulho_regras',
      label: 'Regras para restos de obras',
      responseText: 'Modo Offline - Regras de Entulho\n\n'
          'É proibido deitar entulho de construção (tijolos, cimento, areia) nos contentores de lixo doméstico.\n\n'
          'Esses materiais danificam os mecanismos hidráulicos dos camiões de recolha do município.',
    ),
    XeniOfflineOption(
      id: 'entulho_aterro',
      label: 'Aterro Municipal da Beira',
      responseText: 'Modo Offline - Aterro Municipal\n\n'
          'Grandes volumes de entulho devem ser transportados diretamente para o Aterro Municipal da Beira ou recolhidos mediante agendamento de caçamba junto ao Conselho Municipal.',
    ),
    _optVoltarMenu,
  ];

  // --- MENU PRINCIPAL INICIAL ---
  static const List<XeniOfflineOption> mainMenuOptions = [
    XeniOfflineOption(
      id: 'reciclagem',
      label: 'Como separar o lixo',
      responseText: 'Modo Offline - Guia de Reciclagem\n\n'
          'A separação de resíduos ajuda a manter a Cidade da Beira limpa e sustentável.\n\n'
          'Selecione abaixo o tipo de resíduo que deseja saber como reciclar:',
      followUpOptions: _subReciclagem,
    ),
    XeniOfflineOption(
      id: 'ecopontos',
      label: 'Onde ficam os pontos de recolha',
      responseText: 'Modo Offline - Pontos de Recolha na Beira\n\n'
          'O Município dispõe de ecopontos e contentores comunitários distribuídos pela cidade.\n\n'
          'Selecione o bairro ou zona para consultar a informação:',
      followUpOptions: _subEcopontos,
    ),
    XeniOfflineOption(
      id: 'denuncia',
      label: 'Como fazer uma denúncia',
      responseText: 'Modo Offline - Denúncias de Resíduos\n\n'
          'Pode reportar acumulação de lixo diretamente pela aplicação móvel Txeneza.\n\n'
          'O que deseja saber sobre o processo de denúncia?',
      followUpOptions: _subDenuncia,
    ),
    XeniOfflineOption(
      id: 'prazos',
      label: 'Prazos e acompanhamento',
      responseText: 'Modo Offline - Prazos de Resposta\n\n'
          'Todas as denúncias são submetidas a avaliação e acompanhamento técnico.\n\n'
          'Selecione uma opção para mais detalhes:',
      followUpOptions: _subPrazos,
    ),
    XeniOfflineOption(
      id: 'horarios',
      label: 'Horários de recolha',
      responseText: 'Modo Offline - Horários de Recolha\n\n'
          'A recolha comunitária é dividida por turnos operacionais diários.\n\n'
          'Escolha o turno sobre o qual pretende obter informação:',
      followUpOptions: _subHorarios,
    ),
    XeniOfflineOption(
      id: 'entulho',
      label: 'Entulho e restos de obras',
      responseText: 'Modo Offline - Entulho de Construção\n\n'
          'Resíduos pesados de obras possuem regras específicas de eliminação.\n\n'
          'Selecione o tópico pretendido:',
      followUpOptions: _subEntulho,
    ),
    XeniOfflineOption(
      id: 'suporte',
      label: 'Contactos e Apoio Municipal',
      responseText: 'Modo Offline - Apoio e Contacto\n\n'
          'Para apoio do Conselho Municipal da Cidade da Beira:\n\n'
          '- E-mail: suporte@txeneza.gov.mz\n'
          '- Atendimento Presencial: Balcão Único do Conselho Municipal da Cidade da Beira\n'
          '- Menu da App: Perfil > Ajuda & Suporte',
      followUpOptions: [
        _optVoltarMenu,
      ],
    ),
  ];

  /// Resposta de fallback quando ocorre uma falha na API do Gemini.
  static String getFallbackResponse(String userPrompt) {
    return 'Modo Offline - Assistente Xeni\n\n'
        'Não foi possível ligar aos servidores no momento. Por favor, utilize as opções clicáveis no ecrã para consultar informações de saneamento e reciclagem na Cidade da Beira.';
  }
}
