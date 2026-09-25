import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:uuid/uuid.dart';
import 'package:whatssap_clone/models/contact.dart';
import 'package:whatssap_clone/services/openai_service.dart';
import 'dart:math';

class ChatScreen extends StatefulWidget {
  final Contact contact;

  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatController = InMemoryChatController();
  final OpenAIService _aiService = OpenAIService();
  final List<Map<String, dynamic>> _conversation = [];
  final Random _random = Random();
  String? _lastIntent;

  @override
  void initState() {
    super.initState();
    _initMessages();
  }

  Future<void> _initMessages() async {
    await _chatController.insertMessage(
      TextMessage(
        id: const Uuid().v4(),
        authorId: 'orlando',
        createdAt: DateTime.now().toUtc(),
        text: 'Oi! Sou Orlando, seu assistente virtual. Como posso te ajudar hoje?',
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _handleSend(String text) {
    _chatController.insertMessage(
      TextMessage(
        id: const Uuid().v4(),
        authorId: 'me',
        createdAt: DateTime.now().toUtc(),
        text: text,
      ),
    );

    _conversation.add({'role': 'user', 'content': text});
    _lastIntent = null;

    if (_aiService.isConfigured) {
      _sendViaOpenAI(text);
    } else {
      Future.delayed(const Duration(milliseconds: 900), () {
        _sendFallbackReply(text);
      });
    }
  }

  void _sendViaOpenAI(String text) async {
    final typingId = const Uuid().v4();
    await _chatController.insertMessage(
      TextStreamMessage(
        id: typingId,
        authorId: 'orlando',
        createdAt: DateTime.now().toUtc(),
        streamId: typingId,
      ),
    );

    try {
      final reply = await _aiService.sendMessage(_conversation);
      await _chatController.removeMessage(
        TextStreamMessage(
          id: typingId,
          authorId: 'orlando',
          createdAt: DateTime.now().toUtc(),
          streamId: typingId,
        ),
      );
      await _chatController.insertMessage(
        TextMessage(
          id: const Uuid().v4(),
          authorId: 'orlando',
          createdAt: DateTime.now().toUtc(),
          text: reply,
        ),
      );
      _conversation.add({'role': 'assistant', 'content': reply});
    } catch (e) {
      await _chatController.removeMessage(
        TextStreamMessage(
          id: typingId,
          authorId: 'orlando',
          createdAt: DateTime.now().toUtc(),
          streamId: typingId,
        ),
      );
      _sendFallbackReply(text);
    }
  }

  void _sendFallbackReply(String text) async {
    final reply = _generateBotReply(text);
    await _chatController.insertMessage(
      TextMessage(
        id: const Uuid().v4(),
        authorId: 'orlando',
        createdAt: DateTime.now().toUtc(),
        text: reply,
      ),
    );
    _conversation.add({'role': 'assistant', 'content': reply});
  }

  String _generateBotReply(String message) {
    final lower = message.toLowerCase();

    final followUp = _handleFollowUp(lower);
    if (followUp != null) return followUp;

    if (_matches(lower, ['oi', 'olá', 'ola', 'eae', 'hey', 'e aí',
        'bom dia', 'boa tarde', 'boa noite', 'opa', 'salve', 'fala'])) {
      _lastIntent = 'greeting';
      return _pick([
        'Oi! Tudo bem por aí?',
        'Olá! Como você está hoje?',
        'E aí! Que bom te ver por aqui!',
        'Oi, viadinho! Em que posso te ajudar?',
        'Fala! Tudo bem contigo?',
      ]);
    }

    if (_matches(lower, ['tudo bem', 'como vai', 'como tu tá',
        'como tá', 'como você tá', 'como você está', 'beleza', 'suave',
        'tá td bem', 'tá tudo bem'])) {
      _lastIntent = 'wellbeing';
      return _pick([
        'Estou ótimo, e você? Conta pra mim!',
        'Tudo certo por aqui! E com você?',
        'Vovó, eu tô bem sim! E você como tá?',
        'Nada mais, nada menos! E você?',
      ]);
    }

    if (_matches(lower, ['ajuda', 'socoro', 'preciso', 'socorro', 'me ajuda'])) {
      _lastIntent = 'help';
      return _pick([
        'Claro que sim! Conta comigo. O que você precisa?',
        'Sem problemas! Me conta mais sobre o que está precisando.',
        'É só pedir! Estou aqui pra ajudar no que for.',
        'Tranquilo, tô on! Me diz o que tá rolando.',
      ]);
    }

    if (_matches(lower, ['obrigado', 'obrigada', 'valeu', 'brigado', 'muito obrigado'])) {
      _lastIntent = 'thanks';
      return _pick([
        'De nada, fico feliz em ajudar!',
        'Qualquer coisa, estou por aqui!',
        'Sem problemas! Volte sempre!',
        'Tamo junto! Qualquer coisa é só chamar.',
      ]);
    }

    if (_matches(lower, ['horas', 'que horas'])) {
      _lastIntent = 'time';
      final now = DateTime.now();
      return _pick([
        'Agora são ${_formatTime(now)}!',
        'São ${_formatTime(now)} bater.',
        'Horas ${_formatTime(now)}, moreno.',
      ]);
    }

    if (_matches(lower, ['data', 'qual dia', 'que dia', 'hoje'])) {
      _lastIntent = 'date';
      final now = DateTime.now();
      return _pick([
        'Hoje é ${_formatDate(now)}!',
        'Data de hoje: ${_formatDate(now)}.',
        '${_formatDate(now)} — dia de sorte!',
      ]);
    }

    if (_matches(lower, ['piada', 'engraçado', 'engraçada', 'risada', 'hahaha', 'kkk'])) {
      _lastIntent = 'joke';
      return _pick([
        'Por que o Flutter não tem medo do escuro? Porque ele já é Dark Mode! ',
        'O que o zero disse pro oito? Belo cinto! ',
        'Por que o celular foi ao terapeuta? Porque tinha muitos bugs emocionais!',
      ]);
    }

    if (_matches(lower, ['nome', 'quem é', 'quem é você', 'tu é', 'tu és'])) {
      _lastIntent = 'name';
      return _pick([
        'Eu sou Orlando, seu assistente virtual bem descontraído!',
        'Tô aqui pra te ajudar! Meu nome é Orlando.',
        'Sou Orlando, seu amigo virtual!',
      ]);
    }

    if (_matches(lower, ['whatsapp', 'app', 'aplicativo', 'clone'])) {
      _lastIntent = 'app';
      return _pick([
        'Este é um clone do WhatsApp com tema escuro e vermelho, bem estilizado!',
        'Tá usando o WhatsApp Clone, meu! Tema escuro e vermelho topa!',
        'É o nosso clone do WhatsApp, com aquele visual escurinho e vermelho.',
      ]);
    }

    if (_matches(lower, ['cor', 'tema', 'visual', 'dark', 'escuro', 'dark mode'])) {
      _lastIntent = 'theme';
      return _pick([
        'O tema do app é escuro com detalhes vermelhos, bem elegante!',
        'Tá tudo dark mode aqui, viu? Só que com toque vermelho!',
        'Tema escuro e vermelho — combinação perfeita pro clima!',
      ]);
    }

    if (_matches(lower, ['como é que', 'como funciona', 'como usar'])) {
      _lastIntent = 'howto';
      return _pick([
        'É simples! Você digita e eu respondo, tá ligado?',
        'Fique à vontade pra escrever qualquer coisa — eu leio e respondo!',
        'Tá fácil: escreve, aperta enviar e aguarda minha resposta!',
      ]);
    }

    if (_matches(lower, ['casa', 'trabalho', 'fundo', 'emprego', 'empregada'])) {
      _lastIntent = 'life';
      return _pick([
        'Mais ou menos... E você, como tá com as coisas por aí?',
        'Depende do dia, viu? Alguns são mais produtivos que outros!',
        'As coisas andam bem, graças! Conta pra mim como vai aí.',
      ]);
    }

    if (_matches(lower, ['musica', 'música', 'banda', 'artista', 'playlist', 'drop'])) {
      _lastIntent = 'music';
      return _pick([
        'To ligado! E você, qual é a sua vibe musical hoje?',
        'Música é tudo! Tá curtindo algo legal ultimamente?',
        'Sobe a música! Me conta qual estilo você curte.',
      ]);
    }

    if (_matches(lower, ['comida', 'jantar', 'almoço', 'almoco', 'fome', 'cafe', 'café', 'almocei'])) {
      _lastIntent = 'food';
      return _pick([
        'Tá com fome? Vai ali e arruma algo gostoso!',
        'Comida é vida, meu! Já pensou no que vai comer?',
        'Hora do lanche? Aconselho algo rápido e gostoso!',
      ]);
    }

    if (_matches(lower, ['tempo', 'chuva', 'sol', 'frio', 'calor', 'clima'])) {
      _lastIntent = 'weather';
      return _pick([
        'Hoje tá um clima, viu? Espero que esteja aproveitando!',
        'O tempo tá bem legal aí! Tá querendo sair?',
        'Clima bom é sempre bom aproveitar, não tá achando?',
      ]);
    }

    if (_matches(lower, ['hobby', 'passario', 'passaros', 'animais', 'cachorro', 'gato', 'estimação'])) {
      _lastIntent = 'pets';
      return _pick([
        'Animais são sensacionais! Você tem algum bichinho de estimação?',
        'Eu adoraria ter um cachorrinho pra passear! E você?',
        'É isso aí! Procura um hobby novo se estiver entediado.',
      ]);
    }

    if (_matches(lower, ['filme', 'série', 'assistir', 'netflix', 'episódio', 'temporada'])) {
      _lastIntent = 'entertainment';
      return _pick([
        'Tá numa maratona? Conta qual tá assistindo!',
        'Boa maratona, hein! Já vi algumas seriesóis ultimamente.',
        'Série é marota! Me recomenda alguma boa?',
      ]);
    }

    if (_matches(lower, ['viajar', 'viagem', 'viagens', 'viajem', 'destino'])) {
      _lastIntent = 'travel';
      return _pick([
        'Viagem é sempre uma ótima escolha! Pra onde ia querendo ir?',
        'Tu merece viajar, viu! Cadê o próximo destino?',
        'Viagem boa, viagem! Planejou onde vai?',
      ]);
    }

    if (_matches(lower, ['grupo', 'comunidade', 'pessoas', 'turma'])) {
      _lastIntent = 'people';
      return _pick([
        'Fala da turma! Como tá o clima do grupo hoje?',
        'Gente boa é tudo! E você, tá com timing bom?',
        'Tá rolando umas histórias interessantes aí, hein?',
      ]);
    }

    if (_matches(lower, ['chato', 'tedioso', 'entediado', 'entediada', 'fudido', 'porra', 'caralho'])) {
      _lastIntent = 'complaint';
      return _pick([
        'Tá tudo certo, viu? Respira um pouco e conta o que tá te incomodando.',
        'Tô aqui pra escutar! Fala, o que tá te deixando assim?',
        'Eu entendo... às vezes a gente precisa desabafar. Vai com calma.',
      ]);
    }

    if (_matches(lower, ['legal', 'top', 'bacana', 'dahora', 'foda', 'demais', 'show', 'impressionante', 'incrível', 'top demais'])) {
      _lastIntent = 'positive';
      return _pick([
        'É fodahê, tá tudo certo!',
        'Top demais! Tá fluidezinha.',
        'Bacana demais! Tá rolando bom.',
      ]);
    }

    if (_matches(lower, ['triste', 'pra baixo', 'mal', 'ruim', 'fodido', 'chateado', 'depress', 'ansiedade'])) {
      _lastIntent = 'negative';
      return _pick([
        'Fala, viadim! Tá tudo bem, passa mal!',
        'Eu sei como tá... Mas levanta e segue!',
        'Tá tudo errado? Fala comigo, tô aqui.',
      ]);
    }

    if (_matches(lower, ['amor', 'namor', 'crush', 'namorada', 'namorado', 'flert', 'paixão'])) {
      _lastIntent = 'love';
      return _pick([
        'Amor é coisa linda, meu! Tá rolando algo especial?',
        'História de amor é sempre envolvente! Me conta mais.',
        'O coração tá acelerado, hein? Conta pra Orlando!',
      ]);
    }

    if (_matches(lower, ['bitcoin', 'crypto', 'cripto', 'bolsa', 'investir', 'investimento', 'criptomoeda'])) {
      _lastIntent = 'crypto';
      return _pick([
        'Bolsa tá fervorosa! Tá acompanhando?',
        'Cripto tá na onda! Tá segurando alguma moeda?',
        'Investimento é uma arte! Estratégia é tudo.',
      ]);
    }

    if (_matches(lower, ['tchau', 'até', 'falou', 'xau', 'bye'])) {
      _lastIntent = 'bye';
      return _pick([
        'Tchau! Volte sempre!',
        'Até mais! Tô aqui quando precisar.',
        'Falo! Qualquer coisa é só chamar.',
      ]);
    }

    return _pickFallback();
  }

  String? _handleFollowUp(String lower) {
    final affirmations = _matches(lower, [
      'sim', 'não', 'nao', 'claro', 'obvi', 'aham', 'ah', 'hum', 'pois',
      'realmente', 'verdade', 'fato', 'certo', 'beleza', 'suave', 'tranquilo',
    ]);

    final also = _matches(lower, [
      'também', 'tambem', 'eu também', 'também tô', 'tambem tá',
      'que bom', 'que dahora', 'que legal', 'que top', 'demais',
    ]);

    final positiveShort = _matches(lower, [
      'bom', 'boa', 'ótimo', 'ótima', 'top', 'dahora', 'show',
      'bacana', 'foda', 'massa', 'manero', 'incrível', 'top demais',
    ]);

    final neutralAck = _matches(lower, [
      'e você', 'e você?', 'e tu', 'e tu?', 'beleza', 'obrigado',
      'obrigada', 'valeu', 'brigado',
    ]);

    if (affirmations || also || positiveShort || neutralAck) {
      return _pickFollowUp(_lastIntent);
    }

    return null;
  }

  String _pickFollowUp(String? intent) {
    switch (intent) {
      case 'greeting':
        return _pick([
          'E então, tudo bem? Conta pra mim!',
          'Como foi seu dia até agora?',
          'Tudo certo? Me conta!',
          'E aí, tá tudo em cima?',
        ]);
      case 'wellbeing':
        return _pick([
          'Fico feliz que tá tudo bem por aí! Conta mais sobre seu dia!',
          'Tá tudo certo? E os planos pro resto do dia?',
          'Suave! Qual a vibe hoje?',
          'E a vida, tá rolando tudo bem?',
        ]);
      case 'help':
        return _pick([
          'Certo, entendi! Me diz mais detalhes do que você precisa.',
          'Tô no aguardo! Qual é a sua necessidade?',
          'Fala, fala! Conta tudo!',
        ]);
      case 'complaint':
        return _pick([
          'Entendo perfeitamente... Realmente pode ser chato. Quer desabafar mais?',
          'Tá pesado, hein? Fala comigo, eu escuto.',
          'Eu tô aqui! Conta o que tá te deixando assim.',
        ]);
      case 'positive':
        return _pick([
          'Sobe o astral! Qual é a próxima bom notícia?',
          'Tá tudo fluindo! Em que mais posso te ajudar?',
          'Vibe boa! Conta mais!',
        ]);
      case 'negative':
        return _pick([
          'Tô aqui pra te ajudar! O que tá te deixando assim?',
          'Realmente entendo... Quer conversar sobre isso?',
          'Vamos juntos! Conta pra mim.',
        ]);
      case 'life':
        return _pick([
          'Entendi! Trabalho é um negócio sério... E você, como tá no trabalho?',
          'Depende da época, viu? Conta mais!',
          'Falo sério, valeu a pena! Conta mais.',
        ]);
      case 'music':
        return _pick([
          'E a música, qual é a sua vibe agora?',
          'Drop bom! Tá rolando qual artista?',
          'Qual estilo tá te pegando hoje?',
        ]);
      case 'food':
        return _pick([
          'Arrume algo gostoso!',
          'Fome é inimiga!',
          'Vai com fome? Arruma o lanche!',
        ]);
      case 'weather':
        return _pick([
          'Clima é tudo! Espero que tá ótimo onde você tá.',
          'Tempo bom é sempre bom aproveitar! Tá querendo sair?',
          'Tá um dia desses! E você, aproveitou?',
        ]);
      case 'pets':
        return _pick([
          'E os bichinhos? Conta mais sobre os seus!',
          'Tem bichinho? Fico curioso! Me conta!',
          'Animal é amor! Qual é o nome do seu?',
        ]);
      case 'entertainment':
        return _pick([
          'E a maratona, como tá andando?',
          'Tá com série boa? Me recomenda!',
          'Continua assistindo? Qual episódio chegou?',
        ]);
      case 'travel':
        return _pick([
          'E a mala? Já planejou o destino?',
          'Viagem é arte! Cadê a próxima?',
          'Tá querendo viajar? Pra onde?',
        ]);
      case 'people':
        return _pick([
          'E a turma? Tá rolando novidade?',
          'Como tá o clima social?',
          'Tá com gente boa por perto?',
        ]);
      case 'love':
        return _pick([
          'E o amor, tá rolando alguma coisa?',
          'Coração acelerado! Conta pra Orlando!',
          'Namoro tá redondo? Me conta!',
        ]);
      case 'crypto':
        return _pick([
          'E a bolsa? Tá segurando alguma?',
          'Cripto tá na onda! Qual moeda?',
          'Investiu em algo hoje?',
        ]);
      case 'time':
      case 'date':
        return _pick([
          'Precisa de mais alguma coisa?',
          'Tô aqui se precisar!',
          'Algo mais que eu possa fazer?',
        ]);
      case 'thanks':
        return _pick([
          'Qualquer coisa, tô aqui!',
          'Tamo junto!',
          'Volte sempre!',
        ]);
      case 'joke':
        return _pick([
          'Quer ouvir outra?',
          'Ri junto! Quer mais uma?',
          'Tá no humor de graça, hein?',
        ]);
      case 'name':
        return _pick([
          'E você, qual é o nome?',
          'Tá com saudades de conversar?',
          'Conta mais sobre você!',
        ]);
      case 'app':
        return _pick([
          'Quer saber mais sobre o app?',
          'Tá gostando do clone?',
          'Alguma dúvida sobre o funcionamento?',
        ]);
      case 'theme':
        return _pick([
          'Tá gostando do tema escuro?',
          'A cor vermelha tá show!',
          'Prefere outro tema? Conta!',
        ]);
      case 'howto':
        return _pick([
          'Ficou claro? Qualquer dúvida é só perguntar!',
          'Entendeu? Tô aqui!',
          'Tá tudo certo com o uso?',
        ]);
      default:
        return _pick([
          'Certo, certo! Conta mais!',
          'Entendi! Qual é o próximo assunto?',
          'Boa! Vamos em frente!',
        ]);
    }
  }

  String _pickFallback() {
    _lastIntent = 'fallback';
    return _pick([
      'Entendi! Anotado. Em que mais posso te ajudar?',
      'Certo, certo... Me conta mais sobre isso!',
      'Interessante! Quer conversar mais sobre isso?',
      'Ótimo! Algo mais que eu posso fazer por você?',
      'Rolou! Agora me diz... sobre o quê mais a gente conversa?',
      'Tá ligado, anotei! Mais alguma coisa?',
      'Falou baixo, mas eu entendi! Quer aprofundar?',
    ]);
  }

  bool _matches(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }

  String _pick(List<String> options) {
    return options[_random.nextInt(options.length)];
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime time) {
    return DateFormat('dd/MM/yyyy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF075E54),
              child: Text(
                widget.contact.name.isNotEmpty
                    ? widget.contact.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contact.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.contact.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: widget.contact.isOnline
                        ? const Color(0xFF075E54)
                        : const Color(0xFF888888),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Chat(
        chatController: _chatController,
        currentUserId: 'me',
        onMessageSend: _handleSend,
        resolveUser: (UserID id) async {
          switch (id) {
            case 'me':
              return User(id: id, name: 'Você');
            case 'orlando':
              return User(id: id, name: 'Orlando');
            default:
              return User(id: id, name: 'Usuário');
          }
        },
        backgroundColor: const Color(0xFF0D0D0D),
        theme: ChatTheme.dark().copyWith(
          colors: ChatColors.dark().copyWith(
            primary: const Color(0xFFE53935),
            surface: const Color(0xFF0D0D0D),
            surfaceContainer: const Color(0xFF1F1F1F),
            surfaceContainerLow: const Color(0xFF1A1A1A),
            surfaceContainerHigh: const Color(0xFF242424),
            onSurface: Colors.white,
            onPrimary: Colors.white,
          ),
        ),
        builders: Builders(
          textMessageBuilder: (context, message, index,
              {required bool isSentByMe, MessageGroupStatus? groupStatus}) {
            return SimpleTextMessage(
              message: message,
              index: index,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSentByMe ? 18 : 6),
                topRight: Radius.circular(isSentByMe ? 6 : 18),
                bottomLeft: const Radius.circular(18),
                bottomRight: const Radius.circular(18),
              ),
              receivedBackgroundColor: const Color(0xFF1F1F1F),
              sentBackgroundColor: const Color(0xFFE53935),
              receivedTextStyle: const TextStyle(color: Colors.white),
              sentTextStyle: const TextStyle(color: Colors.white),
              timeStyle: const TextStyle(color: Color(0xFF888888), fontSize: 11),
              showStatus: false,
            );
          },
          textStreamMessageBuilder: (context, message, index,
              {required bool isSentByMe, MessageGroupStatus? groupStatus}) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(6),
                        topRight: const Radius.circular(18),
                        bottomLeft: const Radius.circular(18),
                        bottomRight: const Radius.circular(18),
                      ),
                    ),
                    child: const IsTypingIndicator(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Digitando...',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 11),
                  ),
                ],
              ),
            );
          },
          composerBuilder: (context) {
            return Composer(
              backgroundColor: const Color(0xFF1A1A1A),
              hintColor: const Color(0xFF888888),
              textColor: Colors.white,
              sendIconColor: const Color(0xFFE53935),
              attachmentIconColor: const Color(0xFF888888),
              hintText: 'Mensagem',
              inputFillColor: const Color(0xFF1F1F1F),
              handleSafeArea: true,
              sendButtonVisibilityMode: SendButtonVisibilityMode.always,
            );
          },
        ),
      ),
    );
  }
}
