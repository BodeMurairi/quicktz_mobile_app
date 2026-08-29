import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/conversation_model.dart';

class ConversationRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<ConversationModel>> getMyConversations() async {
    final response = await _dio.get(ApiEndpoints.conversations);
    return (response.data as List)
        .map((e) => ConversationModel.fromJson(e))
        .toList();
  }

  Future<ConversationModel> startConversation(String agencyId) async {
    final response = await _dio
        .post(ApiEndpoints.conversations, data: {'agency_id': agencyId});
    return ConversationModel.fromJson(response.data);
  }

  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    final response =
        await _dio.get(ApiEndpoints.conversationMessages(conversationId));
    return (response.data as List)
        .map((e) => ChatMessageModel.fromJson(e))
        .toList();
  }

  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String text, {
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentType,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.conversationMessages(conversationId),
      data: {
        'text': text,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
        if (attachmentName != null) 'attachment_name': attachmentName,
        if (attachmentType != null) 'attachment_type': attachmentType,
      },
    );
    return ChatMessageModel.fromJson(response.data);
  }

  /// Uploads a file for a message attachment, returns its public URL.
  Future<String> uploadAttachment(String path, String fileName) async {
    final formData = FormData.fromMap({
      'folder': 'attachments',
      'file': await MultipartFile.fromFile(path, filename: fileName),
    });
    final response = await _dio.post(ApiEndpoints.uploads, data: formData);
    return response.data['url'] as String;
  }
}
