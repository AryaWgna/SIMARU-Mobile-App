class AssetDocumentModel {
  final int documentId;
  final String title;
  final String filePath;
  final DateTime uploadDate;
  final int uploadedBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? uploader;
  final List<Map<String, dynamic>>? assets;

  AssetDocumentModel({
    required this.documentId,
    required this.title,
    required this.filePath,
    required this.uploadDate,
    required this.uploadedBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.uploader,
    this.assets,
  });

  factory AssetDocumentModel.fromJson(Map<String, dynamic> json) {
    return AssetDocumentModel(
      documentId: json['document_id'] ?? 0,
      title: json['document_title'] ?? json['title'] ?? '',
      filePath: json['file_path'] ?? '',
      uploadDate: json['upload_date'] != null
          ? DateTime.parse(json['upload_date'])
          : DateTime.now(),
      uploadedBy: json['uploaded_by'] ?? 0,
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      uploader: json['uploader'] != null
          ? Map<String, dynamic>.from(json['uploader'])
          : null,
      assets: json['assets'] != null
          ? List<Map<String, dynamic>>.from(
              json['assets'].map((asset) => Map<String, dynamic>.from(asset)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document_id': documentId,
      'document_title': title,
      'file_path': filePath,
      'upload_date': uploadDate.toIso8601String(),
      'uploaded_by': uploadedBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'uploader': uploader,
      'assets': assets,
    };
  }

  // Helper untuk mendapatkan nama file dari path
  String get fileName {
    if (filePath.isEmpty) return '';
    return filePath.split('/').last;
  }

  // Helper untuk mendapatkan tipe file dari nama file
  String get fileType {
    if (fileName.isEmpty) return '';
    final parts = fileName.split('.');
    if (parts.length <= 1) return '';
    return parts.last.toLowerCase();
  }

  // Helper untuk mendapatkan ukuran file dalam format yang readable
  String get formattedFileSize {
    // Karena ukuran file tidak ada di respons API, kita tidak bisa menampilkan ukuran yang sebenarnya
    return 'Unknown';
  }

  // Helper untuk mendapatkan nama uploader
  String get uploaderName {
    if (uploader != null && uploader!.containsKey('name')) {
      return uploader!['name'] as String;
    }
    return 'Unknown';
  }

  // Helper untuk mendapatkan ikon berdasarkan tipe file
  String getFileIcon() {
    final type = fileType;
    if (type.contains('pdf') || type == 'pdf') {
      return 'pdf';
    } else if (type.contains('image') ||
        ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(type)) {
      return 'image';
    } else if (type.contains('word') || ['doc', 'docx'].contains(type)) {
      return 'word';
    } else if (type.contains('excel') ||
        type.contains('sheet') ||
        ['xls', 'xlsx', 'csv'].contains(type)) {
      return 'excel';
    } else if (type.contains('powerpoint') ||
        type.contains('presentation') ||
        ['ppt', 'pptx'].contains(type)) {
      return 'powerpoint';
    } else if (type.contains('video') ||
        ['mp4', 'avi', 'mov', 'wmv'].contains(type)) {
      return 'video';
    } else if (type.contains('audio') || ['mp3', 'wav', 'ogg'].contains(type)) {
      return 'audio';
    } else if (type.contains('zip') ||
        type.contains('compressed') ||
        ['zip', 'rar', '7z', 'tar', 'gz'].contains(type)) {
      return 'archive';
    } else {
      return 'document';
    }
  }
}
