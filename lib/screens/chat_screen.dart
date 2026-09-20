import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final int rentalId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.rentalId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() {
    return _ChatScreenState();
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final ImagePicker _imagePicker = ImagePicker();

  final List<XFile> _selectedPhotos = [];

  String _messageType = 'CHAT';

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    await Future<void>.delayed(Duration.zero);

    if (!mounted) {
      return;
    }

    await context.read<ChatProvider>().loadConversation(widget.rentalId);

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickFromCamera() async {
    Navigator.pop(context);

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null || !mounted) {
        return;
      }

      if (_selectedPhotos.length >= 8) {
        _showMessage('You can select a maximum of 8 photos.', error: true);
        return;
      }

      setState(() {
        _selectedPhotos.add(photo);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to open the camera.', error: true);
    }
  }

  Future<void> _pickFromGallery() async {
    Navigator.pop(context);

    try {
      final List<XFile> photos = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      if (photos.isEmpty || !mounted) {
        return;
      }

      final int availablePlaces = 8 - _selectedPhotos.length;

      if (availablePlaces <= 0) {
        _showMessage('You can select a maximum of 8 photos.', error: true);
        return;
      }

      setState(() {
        _selectedPhotos.addAll(photos.take(availablePlaces));
      });

      if (photos.length > availablePlaces) {
        _showMessage('Only the first 8 photos were selected.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to open the photo gallery.', error: true);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add inspection photos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Attach up to 8 photos to the rental record.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromCamera,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('CAMERA'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('GALLERY'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);

      if (_selectedPhotos.isEmpty) {
        _messageType = 'CHAT';
      }
    });
  }

  Future<void> _sendMessage() async {
    final ChatProvider provider = context.read<ChatProvider>();

    final String message = _messageController.text.trim();

    if (message.isEmpty && _selectedPhotos.isEmpty) {
      return;
    }

    final bool success = await provider.sendMessage(
      rentalId: widget.rentalId,
      body: message,
      messageType: _messageType,
      photos: List<XFile>.from(_selectedPhotos),
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        provider.sendError ?? 'Unable to send the message.',
        error: true,
      );
      return;
    }

    _messageController.clear();

    setState(() {
      _selectedPhotos.clear();
      _messageType = 'CHAT';
    });

    _scrollToBottom();
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppTheme.errorColor : AppTheme.darkColor,
        ),
      );
  }

  String _formatTime(DateTime date) {
    final DateTime localDate = date.toLocal();

    final String hour = localDate.hour.toString().padLeft(2, '0');

    final String minute = localDate.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDate(DateTime date) {
    final DateTime localDate = date.toLocal();

    final String month = localDate.month.toString().padLeft(2, '0');

    final String day = localDate.day.toString().padLeft(2, '0');

    return '${localDate.year}-$month-$day';
  }

  bool _showDateSeparator(List<ChatMessage> messages, int index) {
    if (index == 0) {
      return true;
    }

    final DateTime current = messages[index].createdAt.toLocal();

    final DateTime previous = messages[index - 1].createdAt.toLocal();

    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  @override
  Widget build(BuildContext context) {
    final ChatProvider provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Rental #${widget.rentalId}',
              style: const TextStyle(
                color: AppTheme.mutedColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _RentalChatBanner(
            carName:
                provider.currentThread?.rental.car.fullName ??
                'Rental conversation',
            rentalStatus: provider.currentThread?.rental.status ?? '',
          ),
          Expanded(child: _buildMessages(provider)),
          if (_selectedPhotos.isNotEmpty)
            _SelectedPhotosBar(
              photos: _selectedPhotos,
              messageType: _messageType,
              onMessageTypeChanged: (String value) {
                setState(() {
                  _messageType = value;
                });
              },
              onRemove: _removePhoto,
            ),
          _MessageComposer(
            controller: _messageController,
            isSending: provider.isSending,
            hasPhotos: _selectedPhotos.isNotEmpty,
            onAttachment: _showAttachmentOptions,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(ChatProvider provider) {
    if (provider.isLoadingThread && provider.currentThread == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.threadError != null && provider.currentThread == null) {
      return _ChatState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load conversation',
        message: provider.threadError!,
        buttonText: 'TRY AGAIN',
        onPressed: _loadConversation,
      );
    }

    if (provider.messages.isEmpty) {
      return _ChatState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Start the conversation',
        message:
            'Send a message or attach pickup and return inspection photos.',
        buttonText: 'REFRESH',
        onPressed: _loadConversation,
      );
    }

    final List<ChatMessage> messages = provider.messages;

    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      onRefresh: () async {
        await provider.loadConversation(widget.rentalId);
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          final ChatMessage message = messages[index];

          return Column(
            children: [
              if (_showDateSeparator(messages, index))
                _DateSeparator(date: _formatDate(message.createdAt)),
              _MessageBubble(
                message: message,
                formattedTime: _formatTime(message.createdAt),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RentalChatBanner extends StatelessWidget {
  final String carName;
  final String rentalStatus;

  const _RentalChatBanner({required this.carName, required this.rentalStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.primaryYellowSoft,
        border: Border(bottom: BorderSide(color: AppTheme.primaryYellowStrong)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow,
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppTheme.darkColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  carName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.darkColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Messages are saved in the rental record.',
                  style: TextStyle(color: AppTheme.textColor, fontSize: 10),
                ),
              ],
            ),
          ),
          if (rentalStatus.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              ),
              child: Text(
                rentalStatus.replaceAll('_', ' '),
                style: const TextStyle(
                  color: AppTheme.primaryBlueDark,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String formattedTime;

  const _MessageBubble({required this.message, required this.formattedTime});

  String _typeLabel() {
    switch (message.messageType) {
      case 'PICKUP_INSPECTION':
        return 'PICKUP INSPECTION';

      case 'RETURN_INSPECTION':
        return 'RETURN INSPECTION';

      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String typeLabel = _typeLabel();

    return Align(
      alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.mine ? AppTheme.primaryBlue : AppTheme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(message.mine ? 12 : 3),
            bottomRight: Radius.circular(message.mine ? 3 : 12),
          ),
          border: message.mine ? null : Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (typeLabel.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: message.mine
                      ? Colors.white.withValues(alpha: 0.17)
                      : AppTheme.primaryYellowSoft,
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: message.mine ? Colors.white : AppTheme.darkColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 9),
            ],
            if (message.attachments.isNotEmpty)
              _MessagePhotos(message: message),
            if (message.hasText) ...[
              if (message.attachments.isNotEmpty) const SizedBox(height: 9),
              Text(
                message.body,
                style: TextStyle(
                  color: message.mine ? Colors.white : AppTheme.darkColor,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    color: message.mine ? Colors.white70 : AppTheme.mutedColor,
                    fontSize: 9,
                  ),
                ),
                if (message.mine) ...[
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.done_all_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagePhotos extends StatelessWidget {
  final ChatMessage message;

  const _MessagePhotos({required this.message});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: message.attachments.map((attachment) {
        return GestureDetector(
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: Colors.black,
                  insetPadding: const EdgeInsets.all(14),
                  child: Stack(
                    children: [
                      InteractiveViewer(
                        child: _AuthenticatedImage(
                          path: attachment.url,
                          width: double.infinity,
                          height: 520,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton.filled(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _AuthenticatedImage(
              path: attachment.url,
              width: 105,
              height: 105,
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AuthenticatedImage extends StatefulWidget {
  final String path;
  final double width;
  final double height;
  final BoxFit fit;

  const _AuthenticatedImage({
    required this.path,
    required this.width,
    required this.height,
    required this.fit,
  });

  @override
  State<_AuthenticatedImage> createState() {
    return _AuthenticatedImageState();
  }
}

class _AuthenticatedImageState extends State<_AuthenticatedImage> {
  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  Future<Uint8List> _loadImage() async {
    final Response<List<int>> response = await ApiClient.dio.get<List<int>>(
      widget.path,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data ?? <int>[]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Image.memory(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: AppTheme.borderSoft,
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppTheme.mutedColor,
            ),
          );
        }

        return Container(
          width: widget.width,
          height: widget.height,
          color: AppTheme.borderSoft,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

class _SelectedPhotosBar extends StatelessWidget {
  final List<XFile> photos;
  final String messageType;
  final ValueChanged<String> onMessageTypeChanged;
  final ValueChanged<int> onRemove;

  const _SelectedPhotosBar({
    required this.photos,
    required this.messageType,
    required this.onMessageTypeChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(width: 8);
              },
              itemBuilder: (BuildContext context, int index) {
                return _SelectedPhoto(
                  photo: photos[index],
                  onRemove: () {
                    onRemove(index);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 9),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TypeChoice(
                  label: 'REGULAR',
                  selected: messageType == 'CHAT',
                  onTap: () {
                    onMessageTypeChanged('CHAT');
                  },
                ),
                const SizedBox(width: 7),
                _TypeChoice(
                  label: 'PICKUP INSPECTION',
                  selected: messageType == 'PICKUP_INSPECTION',
                  onTap: () {
                    onMessageTypeChanged('PICKUP_INSPECTION');
                  },
                ),
                const SizedBox(width: 7),
                _TypeChoice(
                  label: 'RETURN INSPECTION',
                  selected: messageType == 'RETURN_INSPECTION',
                  onTap: () {
                    onMessageTypeChanged('RETURN_INSPECTION');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedPhoto extends StatelessWidget {
  final XFile photo;
  final VoidCallback onRemove;

  const _SelectedPhoto({required this.photo, required this.onRemove});

  Future<Uint8List> _loadBytes() async {
    return photo.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FutureBuilder<Uint8List>(
            future: _loadBytes(),
            builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
              if (snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  width: 74,
                  height: 74,
                  fit: BoxFit.cover,
                );
              }

              return Container(
                width: 74,
                height: 74,
                color: AppTheme.borderSoft,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
        ),
        Positioned(
          right: -5,
          top: -5,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 23,
              height: 23,
              decoration: const BoxDecoration(
                color: AppTheme.errorDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryYellow : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          border: Border.all(
            color: selected
                ? AppTheme.primaryYellowStrong
                : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.darkColor : AppTheme.mutedColor,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool hasPhotos;
  final VoidCallback onAttachment;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.hasPhotos,
    required this.onAttachment,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 10),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: AppTheme.borderSoft)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12171717),
            offset: Offset(0, -5),
            blurRadius: 15,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Attach photos',
              onPressed: isSending ? null : onAttachment,
              icon: Icon(
                hasPhotos
                    ? Icons.add_photo_alternate_rounded
                    : Icons.add_photo_alternate_outlined,
                color: AppTheme.primaryBlue,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                ),
              ),
            ),
            const SizedBox(width: 7),
            SizedBox(
              width: 46,
              height: 46,
              child: IconButton.filled(
                tooltip: 'Send',
                onPressed: isSending ? null : onSend,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  disabledBackgroundColor: AppTheme.borderColor,
                ),
                icon: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final String date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13, top: 3),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.borderSoft,
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            ),
            child: Text(
              date,
              style: const TextStyle(
                color: AppTheme.mutedColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _ChatState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final Future<void> Function() onPressed;

  const _ChatState({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 70),
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueSoft,
              borderRadius: BorderRadius.circular(AppTheme.largeRadius),
              border: Border.all(color: AppTheme.primaryBlue),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 41),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 9),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 23),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(buttonText),
        ),
      ],
    );
  }
}
