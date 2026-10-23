# **TXENEZA MOBILE: APLICAÇÃO MÓVEL DE PARTICIPAÇÃO CÍVICA E REPORTE URBANO**

## **Visão geral da solução**

A aplicação Txeneza Mobile constitui o canal direto de interação entre o munícipe e os serviços de gestão ambiental e de infraestruturas da Cidade da Beira. Projetada para dispositivos móveis Android e iOS com recurso ao ecossistema Flutter, a ferramenta capacita a comunidade local a sinalizar, georreferenciar e acompanhar a resolução de problemas urbanos, com destaque para a gestão de resíduos sólidos, contentores danificados e anomalias sanitárias.

A solução opera com tolerância a conectividade intermitente através de mecanismos de persistência local e sincronização diferida, garantindo que o cidadão possa registar uma ocorrência em qualquer ponto do território e transmiti-la logo que o acesso à rede seja restabelecido.

## **Objetivos do projeto**

1. Democratizar o acesso dos munícipes aos canais de comunicação com a administração municipal.
2. Agilizar a identificação de depósitos informais de lixo e pontos de estrangulamento sanitário através de dados com geolocalização precisa por GPS.
3. Permitir o acompanhamento contínuo e transparente do estado de resolução das solicitações apresentadas.
4. Fornecer orientação educativa sobre gestão de resíduos e posturas municipais através de um assistente de inteligência artificial interativo.
5. Garantir a operacionalidade do registo de ocorrências em condições de conectividade nula ou degradada.

## **Arquitetura técnica e tecnologias**

A aplicação foi estruturada segundo os princípios de arquitetura limpa (Clean Architecture), promovendo a separação rigorosa de responsabilidades entre as camadas de apresentação, domínio de negócio e acesso a dados:

- **Plataforma base**: Flutter SDK (linguagem Dart), assegurando desempenho nativo e paridade comportamental entre ecossistemas móveis.
- **Gestão de estado**: Padrões de arquitetura reativa com Cubit, BLoC e gestores de estado desacoplados por funcionalidade.
- **Camada de dados e autenticação**: Supabase Flutter SDK, operando sobre canais de tempo real para receção instantânea de atualizações e armazenamento seguro de dados de utilizador com Row Level Security.
- **Cartografia móvel**: Mapbox Maps SDK for Flutter, disponibilizando estilos vetoriais de elevado desempenho, marcação de coordenadas em tempo real e visualização de pontos de recolha homologados.
- **Persistência local e sincronização offline**: Motor de armazenamento local com fila de mutações transacionais, assegurando resiliência operacional sem perda de dados na ausência de rede.
- **Inteligência artificial cívica**: Google Gemini AI integrado no módulo de apoio conversacional e triagem temática preliminar de denúncias.
- **Comunicação por notificações**: Integração de serviços de notificação para receção de alertas emitidos aquando da atualização de estado pelas equipas municipais.

## **Estrutura de módulos da aplicação**

O código-fonte reside no diretório `lib/features` e divide-se nos seguintes domínios:

- `denuncia`: Fluxo estruturado de submissão de incidentes com captura de fotografias pela câmara, posicionamento por satélite e classificação de tipologia de resíduo.
- `occurrence`: Visualização aprofundada das ocorrências submetidas, histórico temporal de intervenções e comparação visual com as evidências de resolução enviadas pelos serviços técnicos.
- `home`: Ecrã central do utilizador contendo métricas cívicas individuais, atalhos operacionais e resumo das denúncias ativas.
- `map`: Cartografia interativa com identificação dos contentores de lixo municipais e distribuição de ocorrências nas imediações do munícipe.
- `chatIA`: Assistente de inteligência artificial dedicado ao esclarecimento de dúvidas sobre reciclagem, descarte apropriado e legislação ambiental municipal.
- `notification`: Painel de receção e leitura de notificações com ligação direta ao histórico de cada ocorrência.
- `sync`: Mecanismos de monitorização de conectividade e despacho automático de ocorrências acumuladas na fila local.
- `profile`: Gestão de perfil de cidadão, histórico de participações e configurações da aplicação.
- `auth`: Autenticação segura, criação de conta de munícipe e gestão de credenciais locais.
- `onboarding`: Apresentação pedagógica dos objetivos da plataforma e solicitação orientada de permissões de câmara e localização.

## **Configuração de variáveis de ambiente**

A aplicação móvel lê as suas configurações a partir de um ficheiro `.env` localizado na raiz do projeto. O modelo de configuração encontra-se estruturado no ficheiro `.env.example`:

| Chave de configuração | Finalidade técnica | Observações de segurança |
| :--- | :--- | :--- |
| `MAPBOX_ACCESS_TOKEN` | Carregamento de estilos de mapa e geocodificação | Chave pública móvel |
| `MAPBOX_DOWNLOADS_TOKEN` | Descarregamento do SDK nativo nas plataformas Android e iOS | Configurar em ficheiros de ambiente do sistema de compilação |
| `GEMINI_API_KEY` | Motor de inteligência artificial para o assistente conversacional | Restringir no Google Cloud Console por assinatura SHA-1 e pacote da app |
| `SUPABASE_URL` | Endereço do ponto de terminação da infraestrutura Supabase | Chave de ligação institucional |
| `SUPABASE_ANON_KEY` | Chave anónima para operações públicas protegidas por RLS | Chave de distribuição pública |
| `MAPBOX_STYLE_NORMAL` | Identificador URI do estilo de mapa padrão | Configuração de cartografia |
| `MAPBOX_STYLE_SATELLITE` | Identificador URI do estilo de mapa satélite | Configuração de cartografia |

## **Instruções de segurança para publicação**

Durante a fase de desenvolvimento, o ficheiro `.env` pode ser empacotado como recurso interno da aplicação. Contudo, antes da distribuição final do pacote de instalação (APK ou IPA), devem ser observadas as seguintes salvaguardas:

1. A chave `GEMINI_API_KEY` deve conter restrições ativas no Google Cloud Console, vinculando o seu uso exclusivo ao identificador de pacote da aplicação e à impressão digital SHA-1 do certificado de assinatura de compilação.
2. Em implementações de produção recomendadas, as chamadas a serviços de inteligência artificial devem ser mediadas por rotas de extremidade da plataforma Txeneza Web, impedindo qualquer extração da chave a partir de engenharia inversa do pacote do cliente.
3. As credenciais de acesso anónimas do Supabase dependem da correta parametrização das políticas de segurança ao nível de linha (RLS) configuradas na base de dados central.

## **Procedimentos de execução e compilação**

Para inicializar a aplicação em ambiente de desenvolvimento local:

1. Obter os pacotes e dependências definidos no ficheiro `pubspec.yaml`:
   ```bash
   flutter pub get
   ```

2. Validar a integridade estrutural e tipográfica do código-fonte:
   ```bash
   flutter analyze
   ```

3. Executar a aplicação num dispositivo físico ou emulador conectado:
   ```bash
   flutter run
   ```

4. Gerar o pacote final para distribuição no sistema operativo Android:
   ```bash
   flutter build apk --release
   ```
