import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class NotesScreen extends StatefulWidget {
  final int userId;

  const NotesScreen({super.key, required this.userId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Map<String, dynamic>> _notes = [];

  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> get _filteredNotes {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _notes;
    }

    return _notes.where((note) {
      final title = note['title']?.toString().toLowerCase() ?? '';
      final content = note['content']?.toString().toLowerCase() ?? '';

      return title.contains(query) || content.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // ============================================================
  // LOAD NOTES
  // ============================================================

  Future<void> _loadNotes() async {
    try {
      final notes = await ApiService.getNotes(widget.userId);

      if (!mounted) {
        return;
      }

      setState(() {
        _notes
          ..clear()
          ..addAll(notes.map((note) => Map<String, dynamic>.from(note)));

        _sortNotes();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);

      messenger.showSnackBar(
        SnackBar(content: Text('Could not load notes: $error')),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is DateTime) {
      return value;
    }

    final parsed = DateTime.tryParse(value.toString());

    return parsed ?? DateTime.now();
  }

  String _formatDate(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} • $hour:$minute $period';
  }

  // ============================================================
  // SORT NOTES
  // ============================================================

  void _sortNotes() {
    _notes.sort((a, b) {
      final aPinned = a['pinned'] == true || a['pinned']?.toString() == '1';

      final bPinned = b['pinned'] == true || b['pinned']?.toString() == '1';

      if (aPinned && !bPinned) {
        return -1;
      }

      if (!aPinned && bPinned) {
        return 1;
      }

      final aDate = _parseDate(a['updated_at'] ?? a['created_at']);

      final bDate = _parseDate(b['updated_at'] ?? b['created_at']);

      return bDate.compareTo(aDate);
    });
  }

  // ============================================================
  // ADD NOTE
  // ============================================================

  Future<void> _addNote() async {
    if (_isSaving) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
    );

    if (result == null) {
      return;
    }

    final title = result['title']?.toString().trim() ?? '';

    final content = result['content']?.toString().trim() ?? '';

    final pinned = result['pinned'] == true;

    if (title.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a title.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final createdNote = await ApiService.createNote(
        userId: widget.userId,
        title: title,
        content: content.isEmpty ? null : content,
        pinned: pinned,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _notes.insert(0, Map<String, dynamic>.from(createdNote));

        _sortNotes();
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Note created successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Could not create note: $error')),
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // ============================================================
  // EDIT NOTE
  // ============================================================

  Future<void> _editNote(Map<String, dynamic> note) async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );

    if (result == null) {
      return;
    }

    final noteId = note['id'];

    if (noteId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Cannot update this note.')),
      );
      return;
    }

    final title = result['title']?.toString().trim() ?? '';

    final content = result['content']?.toString().trim() ?? '';

    final pinned = result['pinned'] == true;

    if (title.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a title.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedNote = await ApiService.updateNote(
        noteId: int.parse(noteId.toString()),
        title: title,
        content: content.isEmpty ? null : content,
        pinned: pinned,
      );

      if (!mounted) {
        return;
      }

      final index = _notes.indexWhere(
        (item) => item['id'].toString() == noteId.toString(),
      );

      if (index != -1) {
        setState(() {
          _notes[index] = Map<String, dynamic>.from(updatedNote);

          _sortNotes();
        });
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Note updated successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Could not update note: $error')),
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // ============================================================
  // DELETE NOTE
  // ============================================================

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    final messenger = ScaffoldMessenger.of(context);

    final title = note['title']?.toString() ?? 'this note';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete note?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.expense,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final noteId = note['id'];

    if (noteId == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.deleteNote(int.parse(noteId.toString()));

      if (!mounted) {
        return;
      }

      setState(() {
        _notes.removeWhere(
          (item) => item['id'].toString() == noteId.toString(),
        );
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Note deleted successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete note: $error')),
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // ============================================================
  // PIN / UNPIN
  // ============================================================

  Future<void> _togglePin(Map<String, dynamic> note) async {
    final messenger = ScaffoldMessenger.of(context);

    final noteId = note['id'];

    if (noteId == null) {
      return;
    }

    try {
      final updatedNote = await ApiService.toggleNotePin(
        int.parse(noteId.toString()),
      );

      if (!mounted) {
        return;
      }

      final index = _notes.indexWhere(
        (item) => item['id'].toString() == noteId.toString(),
      );

      if (index != -1) {
        setState(() {
          _notes[index] = Map<String, dynamic>.from(updatedNote);

          _sortNotes();
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Could not update pin: $error')),
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search notes...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  Navigator.pop(sheetContext);
                },
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final notes = _filteredNotes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Notes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showSearch,
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : notes.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadNotes,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
                children: [
                  if (_searchQuery.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '${notes.length} result${notes.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ...notes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildNoteCard(note),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : _addNote,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // ============================================================
  // NOTE CARD
  // ============================================================

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final title = note['title']?.toString() ?? 'Untitled';

    final content = note['content']?.toString() ?? '';

    final date = _parseDate(note['updated_at'] ?? note['created_at']);

    final pinned = note['pinned'] == true || note['pinned']?.toString() == '1';

    return GestureDetector(
      onTap: () => _editNote(note),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (pinned)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.push_pin_rounded,
                      color: AppColors.primary,
                      size: 17,
                    ),
                  ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textMuted,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editNote(note);
                        break;

                      case 'pin':
                        _togglePin(note);
                        break;

                      case 'delete':
                        _deleteNote(note);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(pinned ? 'Unpin' : 'Pin'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AppColors.expense),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (content.trim().isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 13),
            Text(
              _formatDate(date),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final searching = _searchQuery.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.note_alt_rounded,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              searching ? 'No notes found' : 'No notes yet',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? 'Try searching with a different word.'
                  : 'Create notes to keep important information handy.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            if (!searching) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _addNote,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Note'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// NOTE EDITOR
// ============================================================================

class NoteEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? note;

  const NoteEditorScreen({super.key, this.note});

  bool get isEditing => note != null;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;

  late final TextEditingController _contentController;

  bool _pinned = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.note?['title']?.toString() ?? '',
    );

    _contentController = TextEditingController(
      text: widget.note?['content']?.toString() ?? '',
    );

    _pinned =
        widget.note?['pinned'] == true ||
        widget.note?['pinned']?.toString() == '1';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ============================================================
  // SAVE EDITOR
  // ============================================================

  void _save() {
    final title = _titleController.text.trim();

    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title or note.')),
      );
      return;
    }

    Navigator.pop(context, {
      'title': title.isEmpty ? 'Untitled' : title,
      'content': content,
      'pinned': _pinned,
    });
  }

  // ============================================================
  // BUILD EDITOR
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          widget.isEditing ? 'Edit Note' : 'New Note',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _pinned = !_pinned;
              });
            },
            icon: Icon(
              _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _pinned ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Title',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 9),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Note title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Note',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 9),
              TextField(
                controller: _contentController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'Write your note here...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 125),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Pin this note',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Keep it at the top of your notes',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  value: _pinned,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _pinned = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.isEditing ? 'Save Changes' : 'Save Note'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
