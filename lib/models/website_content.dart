class ThoughtOfTheDay {
  final String text;
  final String? author;

  const ThoughtOfTheDay({required this.text, this.author});

  Map<String, dynamic> toJson() => {'text': text, 'author': author};

  factory ThoughtOfTheDay.fromJson(Map<String, dynamic> json) =>
      ThoughtOfTheDay(
        text: json['text'] as String? ?? '',
        author: json['author'] as String?,
      );
}

class UpcomingEvent {
  final String title;
  final String? details;

  const UpcomingEvent({required this.title, this.details});

  Map<String, dynamic> toJson() => {'title': title, 'details': details};

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) => UpcomingEvent(
    title: json['title'] as String? ?? '',
    details: json['details'] as String?,
  );
}

class WebsiteContent {
  final ThoughtOfTheDay? thoughtOfTheDay;
  final List<UpcomingEvent> upcomingEvents;
  final List<String> carouselImages;
  final DateTime fetchedAt;

  const WebsiteContent({
    this.thoughtOfTheDay,
    this.upcomingEvents = const [],
    this.carouselImages = const [],
    required this.fetchedAt,
  });

  Map<String, dynamic> toJson() => {
    'thoughtOfTheDay': thoughtOfTheDay?.toJson(),
    'upcomingEvents': upcomingEvents.map((e) => e.toJson()).toList(),
    'carouselImages': carouselImages,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory WebsiteContent.fromJson(Map<String, dynamic> json) => WebsiteContent(
    thoughtOfTheDay: json['thoughtOfTheDay'] != null
        ? ThoughtOfTheDay.fromJson(
            Map<String, dynamic>.from(json['thoughtOfTheDay'] as Map),
          )
        : null,
    upcomingEvents: (json['upcomingEvents'] as List<dynamic>? ?? [])
        .map((e) => UpcomingEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    carouselImages: (json['carouselImages'] as List<dynamic>? ?? [])
        .map((e) => e as String? ?? '')
        .where((e) => e.isNotEmpty)
        .toList(),
    fetchedAt:
        DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class DonateContent {
  final List<String> introParagraphs;
  final String? zelleEmail;
  final String? zelleInstruction;
  final String? zelleQrImageUrl;
  final String? checkInstruction;
  final List<String> checkMailingAddress;
  final String? paypalGivingInstruction;
  final String? paypalGivingUrl;
  final String? paypalGivingNote;
  final String? creditCardInstruction;
  final String? creditCardUrl;
  final String? creditCardNote;
  final String? matchingGrantInstruction;
  final String? matchingFormUrl;
  final DateTime fetchedAt;

  const DonateContent({
    this.introParagraphs = const [],
    this.zelleEmail,
    this.zelleInstruction,
    this.zelleQrImageUrl,
    this.checkInstruction,
    this.checkMailingAddress = const [],
    this.paypalGivingInstruction,
    this.paypalGivingUrl,
    this.paypalGivingNote,
    this.creditCardInstruction,
    this.creditCardUrl,
    this.creditCardNote,
    this.matchingGrantInstruction,
    this.matchingFormUrl,
    required this.fetchedAt,
  });

  Map<String, dynamic> toJson() => {
        'introParagraphs': introParagraphs,
        'zelleEmail': zelleEmail,
        'zelleInstruction': zelleInstruction,
        'zelleQrImageUrl': zelleQrImageUrl,
        'checkInstruction': checkInstruction,
        'checkMailingAddress': checkMailingAddress,
        'paypalGivingInstruction': paypalGivingInstruction,
        'paypalGivingUrl': paypalGivingUrl,
        'paypalGivingNote': paypalGivingNote,
        'creditCardInstruction': creditCardInstruction,
        'creditCardUrl': creditCardUrl,
        'creditCardNote': creditCardNote,
        'matchingGrantInstruction': matchingGrantInstruction,
        'matchingFormUrl': matchingFormUrl,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory DonateContent.fromJson(Map<String, dynamic> json) => DonateContent(
        introParagraphs: (json['introParagraphs'] as List<dynamic>? ?? [])
            .map((e) => e as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList(),
        zelleEmail: json['zelleEmail'] as String?,
        zelleInstruction: json['zelleInstruction'] as String?,
        zelleQrImageUrl: json['zelleQrImageUrl'] as String?,
        checkInstruction: json['checkInstruction'] as String?,
        checkMailingAddress:
            (json['checkMailingAddress'] as List<dynamic>? ?? [])
                .map((e) => e as String? ?? '')
                .where((e) => e.isNotEmpty)
                .toList(),
        paypalGivingInstruction: json['paypalGivingInstruction'] as String?,
        paypalGivingUrl: json['paypalGivingUrl'] as String?,
        paypalGivingNote: json['paypalGivingNote'] as String?,
        creditCardInstruction: json['creditCardInstruction'] as String?,
        creditCardUrl: json['creditCardUrl'] as String?,
        creditCardNote: json['creditCardNote'] as String?,
        matchingGrantInstruction: json['matchingGrantInstruction'] as String?,
        matchingFormUrl: json['matchingFormUrl'] as String?,
        fetchedAt:
            DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class CurricularClassesSection {
  final String title;
  final String schedule;
  final String description;

  const CurricularClassesSection({
    required this.title,
    required this.schedule,
    required this.description,
  });
}

class CurricularClassesContent {
  final CurricularClassesSection youngstersSection;
  final CurricularClassesSection adultsSection;
  final String thumbnailUrl;

  const CurricularClassesContent({
    required this.youngstersSection,
    required this.adultsSection,
    required this.thumbnailUrl,
  });
}

class MusicClassSection {
  final String title;
  final String teachers;
  final String schedule;
  final String description;
  final String? formUrl;

  const MusicClassSection({
    required this.title,
    required this.teachers,
    required this.schedule,
    required this.description,
    this.formUrl,
  });
}

class MusicClassesContent {
  final MusicClassSection vocalSection;
  final MusicClassSection tablaSection;
  final String vocalThumbnailUrl;
  final String tablaThumbnailUrl;

  const MusicClassesContent({
    required this.vocalSection,
    required this.tablaSection,
    required this.vocalThumbnailUrl,
    required this.tablaThumbnailUrl,
  });
}

class SummerCampContent {
  final String title;
  final String description;
  final String thumbnailUrl;

  const SummerCampContent({
    required this.title,
    required this.description,
    required this.thumbnailUrl,
  });
}

class Event {
  final String title;
  final String imageUrl;
  final String description;

  const Event({
    required this.title,
    required this.imageUrl,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'imageUrl': imageUrl,
    'description': description,
  };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    title: json['title'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );
}

class EventsContent {
  final List<Event> events;
  final DateTime fetchedAt;

  const EventsContent({this.events = const [], required this.fetchedAt});

  Map<String, dynamic> toJson() => {
    'events': events.map((e) => e.toJson()).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory EventsContent.fromJson(Map<String, dynamic> json) => EventsContent(
    events: (json['events'] as List<dynamic>? ?? [])
        .map((e) => Event.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    fetchedAt:
        DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class BookstoreContent {
  final String title;
  final String about;
  final List<String> locationLines;
  final List<String> hours;
  final String? contactEmail;
  final DateTime fetchedAt;

  const BookstoreContent({
    required this.title,
    required this.about,
    required this.locationLines,
    required this.hours,
    this.contactEmail,
    required this.fetchedAt,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'about': about,
    'locationLines': locationLines,
    'hours': hours,
    'contactEmail': contactEmail,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory BookstoreContent.fromJson(Map<String, dynamic> json) =>
      BookstoreContent(
        title: json['title'] as String? ?? '',
        about: json['about'] as String? ?? '',
        locationLines: (json['locationLines'] as List<dynamic>? ?? [])
            .map((e) => e as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList(),
        hours: (json['hours'] as List<dynamic>? ?? [])
            .map((e) => e as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList(),
        contactEmail: json['contactEmail'] as String?,
        fetchedAt:
            DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}


class AdmissionsContent {
  final String? sectionI;
  final String? sectionII;
  final String? sectionIII;
  final String? sectionIV;
  final String? kgFormUrl;
  final String? alternateRouteFormUrl;
  final List<String> addressLines;
  final DateTime fetchedAt;

  const AdmissionsContent({
    this.sectionI,
    this.sectionII,
    this.sectionIII,
    this.sectionIV,
    this.kgFormUrl,
    this.alternateRouteFormUrl,
    this.addressLines = const [],
    required this.fetchedAt,
  });

  Map<String, dynamic> toJson() => {
    'sectionI': sectionI,
    'sectionII': sectionII,
    'sectionIII': sectionIII,
    'sectionIV': sectionIV,
    'kgFormUrl': kgFormUrl,
    'alternateRouteFormUrl': alternateRouteFormUrl,
    'addressLines': addressLines,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory AdmissionsContent.fromJson(Map<String, dynamic> json) =>
      AdmissionsContent(
        sectionI: json['sectionI'] as String?,
        sectionII: json['sectionII'] as String?,
        sectionIII: json['sectionIII'] as String?,
        sectionIV: json['sectionIV'] as String?,
        kgFormUrl: json['kgFormUrl'] as String?,
        alternateRouteFormUrl: json['alternateRouteFormUrl'] as String?,
        addressLines: (json['addressLines'] as List<dynamic>? ?? [])
            .map((e) => e as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList(),
        fetchedAt:
            DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class ContactContent {
  final String? phone;
  final List<String> addressLines;
  final String? absenceTardyInstructions;
  final String? admissionsUrl;
  final String? mondayScripturalClassFormUrl;
  final String? tablaClassFormUrl;
  final String? registrationEmail;
  final String? alumniEmail;
  final String? heroImageUrl;
  final String? generalNotice;
  final DateTime fetchedAt;

  const ContactContent({
    this.phone,
    this.addressLines = const [],
    this.absenceTardyInstructions,
    this.admissionsUrl,
    this.mondayScripturalClassFormUrl,
    this.tablaClassFormUrl,
    this.registrationEmail,
    this.alumniEmail,
    this.heroImageUrl,
    this.generalNotice,
    required this.fetchedAt,
  });

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'addressLines': addressLines,
    'absenceTardyInstructions': absenceTardyInstructions,
    'admissionsUrl': admissionsUrl,
    'mondayScripturalClassFormUrl': mondayScripturalClassFormUrl,
    'tablaClassFormUrl': tablaClassFormUrl,
    'registrationEmail': registrationEmail,
    'alumniEmail': alumniEmail,
    'heroImageUrl': heroImageUrl,
    'generalNotice': generalNotice,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory ContactContent.fromJson(Map<String, dynamic> json) =>
      ContactContent(
        phone: json['phone'] as String?,
        addressLines: (json['addressLines'] as List<dynamic>? ?? [])
            .map((e) => e as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList(),
        absenceTardyInstructions: json['absenceTardyInstructions'] as String?,
        admissionsUrl: json['admissionsUrl'] as String?,
        mondayScripturalClassFormUrl:
            json['mondayScripturalClassFormUrl'] as String?,
        tablaClassFormUrl: json['tablaClassFormUrl'] as String?,
        registrationEmail: json['registrationEmail'] as String?,
        alumniEmail: json['alumniEmail'] as String?,
        heroImageUrl: json['heroImageUrl'] as String?,
        generalNotice: json['generalNotice'] as String?,
        fetchedAt:
            DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
