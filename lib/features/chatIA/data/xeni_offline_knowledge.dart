/// Base de conhecimento offline para a assistente virtual Xeni (Txeneza).
/// Fornece respostas limpas, sem emojis ou marcações de formatação (** ou *).
class XeniOfflineKnowledge {
  XeniOfflineKnowledge._();

  /// Procura e devolve a resposta offline mais adequada com base nas palavras-chave do texto.
  static String getResponse(String userPrompt) {
    final clean = _normalize(userPrompt);

    // 1. Separação de resíduos e Reciclagem
    if (_matches(clean, ['separ', 'recicla', 'organico', 'plastico', 'vidro', 'papel', 'lixo', 'triagem', 'metal'])) {
      return 'Modo Offline - Guia de Reciclagem e Separação\n\n'
          'Na Cidade da Beira, incentive a separação correta dos resíduos:\n\n'
          '- Plásticos e Metais: Garrafas PET, embalagens limpas, sacos plásticos e latas. Coloque no ecoponto amarelo/plástico.\n'
          '- Papel e Cartão: Caixas de papelão secas, jornais, revistas e rascunhos. Coloque no ecoponto azul.\n'
          '- Vidro: Garrafas, frascos e recipientes de vidro inteiros. Coloque no ecoponto verde.\n'
          '- Resíduos Orgânicos: Restos de comida e resíduos de jardim. Coloque em sacos bem vedados nos contentores comunitários.\n'
          '- Resíduos Perigosos: Pilhas, baterias e óleos usados devem ser entregues nos postos municipais de recolha especial.\n\n'
          'Dica: Lave ligeiramente as embalagens antes de descartar para evitar maus odores.';
    }

    // 2. Pontos de Coleta e Ecopontos na Cidade da Beira
    if (_matches(clean, ['ponto', 'ecoponto', 'onde fica', 'onde deitar', 'localiza', 'bairro', 'chaimite', 'munhava', 'ponta gea', 'esturro', 'manga'])) {
      return 'Modo Offline - Pontos de Recolha e Ecopontos\n\n'
          'O Município da Beira dispõe de ecopontos e contentores comunitários em várias zonas da cidade:\n\n'
          '- Ponta Gêa / Chaimite: Ecopontos instalados junto às vias principais e praias.\n'
          '- Munhava / Esturro: Contentores de grande capacidade para resíduos sólidos urbanos.\n'
          '- Manga / Macuti: Pontos de deposição seletiva e comunitária.\n\n'
          'Como encontrar:\n'
          'Pode ver a localização exata de todos os pontos no mapa interativo no separador Início da aplicação móvel.';
    }

    // 3. Como denunciar / Criar ocorrência no Txeneza
    if (_matches(clean, ['denuncia', 'report', 'como fazer', 'foto', 'acumula', 'submeter', 'app'])) {
      return 'Modo Offline - Como Registar uma Denúncia\n\n'
          'Siga estes passos simples para denunciar lixo acumulado:\n\n'
          '1. Toque no botão central da câmara (botão +) na barra inferior da aplicação.\n'
          '2. Tire uma fotografia nítida do local com lixo.\n'
          '3. Verifique se a localização no mapa está correta.\n'
          '4. Selecione a categoria do resíduo e a gravidade.\n'
          '5. Toque em Submeter Denúncia.\n\n'
          'Funciona sem internet: Se estiver offline, a sua denúncia fica guardada com segurança no telemóvel e é enviada automaticamente assim que recuperar a ligação.';
    }

    // 4. Prazos e Acompanhamento de Ocorrências
    if (_matches(clean, ['tempo', 'prazo', 'demora', 'resposta', 'estado', 'acompanhar', 'resolvido', 'minhas ocorrencias'])) {
      return 'Modo Offline - Prazos e Acompanhamento\n\n'
          'Avaliação Inicial: A equipa municipal avalia as denúncias em até 24 a 48 horas.\n'
          'Limpeza e Resolução: O tempo de recolha varia conforme a gravidade e o volume do resíduo.\n'
          'Validação Fotográfica: Após a equipa resolver o problema, receberá uma notificação para validar a resolução com uma foto do local limpo.\n\n'
          'Acompanhar estado: Consulte em Perfil > Minhas Ocorrências para ver o progresso atualizado.';
    }

    // 5. Horários de Recolha Municipal
    if (_matches(clean, ['horario', 'hora', 'quando passa', 'camiao', 'recolha', 'turno'])) {
      return 'Modo Offline - Horários de Recolha\n\n'
          'A recolha de resíduos na Cidade da Beira é realizada pelas equipas municipais nos seguintes horários:\n\n'
          '- Turno da Manhã: 06h00 às 10h00 (Zonas comerciais e vias principais)\n'
          '- Turno da Tarde/Noite: 17h00 às 21h00 (Zonas residenciais e bairros)\n\n'
          'Recomendação: Coloque o seu lixo nos contentores preferencialmente pouco antes dos horários de recolha para evitar acumulação prolongada.';
    }

    // 6. Entulho e Resíduos de Construção
    if (_matches(clean, ['entulho', 'obras', 'construcao', 'areia', 'tijolo', 'grande porte'])) {
      return 'Modo Offline - Entulho e Resíduos de Construção\n\n'
          'Resíduos de obras e entulho de grande porte não devem ser descartados nos contentores normais de lixo doméstico.\n\n'
          '- Devem ser encaminhados para o aterro municipal ou recolhidos via pedido especial ao Conselho Municipal da Beira.\n'
          '- Pode registar uma denúncia na app selecionando a categoria Entulho / Construção para que a equipa avalie o local.';
    }

    // 7. Contacto e Apoio ao Cidadão
    if (_matches(clean, ['contato', 'suporte', 'ajuda', 'telefone', 'email', 'cmb', 'municipio'])) {
      return 'Modo Offline - Apoio e Contacto\n\n'
          'Para esclarecimentos ou apoio adicional do Município da Beira:\n\n'
          '- E-mail de Suporte: suporte@txeneza.gov.mz\n'
          '- Menu da Aplicação: Aceda a Perfil > Ajuda & Suporte ou Reportar um Problema.\n'
          '- Atendimento Presencial: Balcão Único do Conselho Municipal da Cidade da Beira.';
    }

    // 8. Resposta Genérica Offline (Menu Principal de Opções)
    return 'Modo Offline - Assistente Xeni\n\n'
        'Estou a funcionar em modo offline sem acesso direto à internet de momento. No entanto, posso ajudá-lo com as seguintes informações padrão:\n\n'
        '1. Reciclagem: Escreva "como separar o lixo"\n'
        '2. Ecopontos: Escreva "onde ficam os pontos de recolha"\n'
        '3. Denúncias: Escreva "como fazer uma denuncia"\n'
        '4. Prazos: Escreva "tempo de resposta"\n'
        '5. Horários: Escreva "horarios de recolha"\n'
        '6. Contactos: Escreva "suporte e contato"\n\n'
        'Ligue-se à internet para conversa livre com Inteligência Artificial.';
  }

  static bool _matches(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâã]'), 'a')
        .replaceAll(RegExp(r'[éèê]'), 'e')
        .replaceAll(RegExp(r'[íìî]'), 'i')
        .replaceAll(RegExp(r'[óòôõ]'), 'o')
        .replaceAll(RegExp(r'[úùû]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .trim();
  }
}
