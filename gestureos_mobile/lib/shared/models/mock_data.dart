library;

/// Mock data models for Phase 2 UI. No real data, no real storage.

enum FileCategory { images, documents, videos, folders }

class MockFile {
  const MockFile({
    required this.name,
    required this.size,
    required this.extension,
    required this.category,
    this.isSelected = false,
  });

  final String name;
  final String size;
  final String extension;
  final FileCategory category;
  final bool isSelected;

  MockFile copyWith({bool? isSelected}) {
    return MockFile(
      name: name,
      size: size,
      extension: extension,
      category: category,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class MockTransfer {
  const MockTransfer({
    required this.fileName,
    required this.deviceName,
    required this.time,
    required this.size,
    this.isSuccess = true,
  });

  final String fileName;
  final String deviceName;
  final String time;
  final String size;
  final bool isSuccess;
}

abstract final class MockData {
  static const List<MockFile> files = [
    MockFile(name: 'Design_System_v3.fig', size: '24.5 MB', extension: 'fig', category: FileCategory.documents),
    MockFile(name: 'Profile_Photo.jpg', size: '3.2 MB', extension: 'jpg', category: FileCategory.images),
    MockFile(name: 'Quarterly_Report.pdf', size: '8.1 MB', extension: 'pdf', category: FileCategory.documents),
    MockFile(name: 'Product_Demo.mp4', size: '156 MB', extension: 'mp4', category: FileCategory.videos),
    MockFile(name: 'Vacation_Photos', size: '1.2 GB', extension: 'folder', category: FileCategory.folders),
    MockFile(name: 'Logo_Final.png', size: '1.8 MB', extension: 'png', category: FileCategory.images),
    MockFile(name: 'Meeting_Notes.docx', size: '245 KB', extension: 'docx', category: FileCategory.documents),
    MockFile(name: 'Screen_Recording.mov', size: '89 MB', extension: 'mov', category: FileCategory.videos),
    MockFile(name: 'Project_Assets', size: '340 MB', extension: 'folder', category: FileCategory.folders),
    MockFile(name: 'Wallpaper_4K.jpg', size: '12 MB', extension: 'jpg', category: FileCategory.images),
    MockFile(name: 'Budget_2026.xlsx', size: '560 KB', extension: 'xlsx', category: FileCategory.documents),
    MockFile(name: 'Tutorial.mkv', size: '234 MB', extension: 'mkv', category: FileCategory.videos),
  ];

  static const List<MockTransfer> recentTransfers = [
    MockTransfer(fileName: 'Design_v2.fig', deviceName: 'MacBook Pro', time: '2m ago', size: '18.3 MB'),
    MockTransfer(fileName: 'Photo_Shoot.zip', deviceName: 'MacBook Pro', time: '1h ago', size: '245 MB'),
    MockTransfer(fileName: 'Report.pdf', deviceName: 'iMac', time: '3h ago', size: '4.7 MB'),
  ];
}
