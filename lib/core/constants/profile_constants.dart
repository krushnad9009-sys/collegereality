class ProfileConstants {
  ProfileConstants._();

  static const availabilityAvailable = 'available';
  static const availabilityBusy = 'busy';
  static const availabilityOffline = 'offline';

  static const List<Map<String, String>> availabilityOptions = [
    {'id': availabilityAvailable, 'label': 'Available'},
    {'id': availabilityBusy, 'label': 'Busy'},
    {'id': availabilityOffline, 'label': 'Offline'},
  ];

  static const List<String> suggestedInterests = [
    'Coding',
    'Sports',
    'Music',
    'Photography',
    'Startups',
    'Research',
    'Gaming',
    'Debate',
    'Volunteering',
    'Design',
    'Finance',
    'Robotics',
  ];

  static String availabilityLabel(String status) {
    return availabilityOptions
        .firstWhere(
          (o) => o['id'] == status,
          orElse: () => {'id': status, 'label': 'Offline'},
        )['label']!;
  }
}
