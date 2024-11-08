import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:public_chat/features/genai_setting/data/chat_content.dart';
import 'package:public_chat/repository/genai_model.dart';
import 'package:public_chat/service_locator/service_locator.dart';
import 'package:public_chat/utils/bloc_extensions.dart';

part 'genai_event.dart';

part 'genai_state.dart';

class GenaiBloc extends Bloc<GenaiEvent, GenaiState> {
  final List<ChatContent> _content = [];
  final GenAiModel _model = ServiceLocator.instance.get<GenAiModel>();

  GenaiBloc() : super(GenaiInitial()) {
    on<SendMessageEvent>(_sendMessage);
  }

  void _sendMessage(SendMessageEvent event, Emitter<GenaiState> emit) async {
    _content.add(ChatContent.user(event.message));
    _content.add(const ChatContent.gemini("", generating: true));
    emitSafely(MessagesUpdate(List.from(_content)));

    addGenminiResponse(String text) {
      _content.removeLast();
      _content.add(ChatContent.gemini(text));
    }

    try {
      final response = await _model.sendMessage(Content.text(event.message));

      final String? text = response.text;

      if (text == null) {
        addGenminiResponse('Unable to generate response');
      } else {
        addGenminiResponse(text);
      }
    } catch (e) {
      addGenminiResponse('Unable to generate response');
    }

    emitSafely(MessagesUpdate(List.from(_content)));
  }
}
