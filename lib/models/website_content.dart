/// Represents a daily inspirational thought or quote.
/// 
/// This is typically displayed on the home screen to provide
/// daily inspiration to users of the app.
class ThoughtOfTheDay {
  /// The main text content of the thought or quote.
  final String text;
  
  /// Optional author name. Can be null if the author is unknown
  /// or if it's a traditional saying without a specific author.
  final String? author;

  /// Creates a new ThoughtOfTheDay.
  /// 
  /// [text] is required, but [author] is optional.
  const ThoughtOfTheDay({required this.text, this.author});

  /// Converts this object to JSON format for storage.
  Map<String, dynamic> toJson() => {'text': text, 'author': author};

  /// Creates a ThoughtOfTheDay from JSON data.
  /// 
  /// If the text is missing, it defaults to an empty string.
  /// If the author is missing, it remains null.
  factory ThoughtOfTheDay.fromJson(Map<String, dynamic> json) =>
      ThoughtOfTheDay(
        text: json['text'] as String? ?? '',
        author: json['author'] as String?,
      );
}

/// Represents a single upcoming event that will be displayed on the home screen.
/// 
/// This is different from CalendarEvent - this is specifically for
/// highlighting important upcoming events in a prominent way.
class UpcomingEvent {
  /// The name or title of the upcoming event.
  final String title;
  
  /// Optional additional details about the event (time, location, etc.).
  final String? details;

  /// Creates a new UpcomingEvent.
  /// 
  /// [title] is required, but [details] is optional.
  const UpcomingEvent({required this.title, this.details});

  /// Converts this object to JSON format for storage.
  Map<String, dynamic> toJson() => {'title': title, 'details': details};

  /// Creates an UpcomingEvent from JSON data.
  /// 
  /// If the title is missing, it defaults to an empty string.
  /// If the details are missing, it remains null.
  factory UpcomingEvent.fromJson(Map<String, dynamic> json) => UpcomingEvent(
    title: json['title'] as String? ?? '',
    details: json['details'] as String?,
  );
}

/// Main content container for the home screen.
/// 
/// This class holds all the dynamic content that gets displayed on the
/// home screen: the thought of the day, upcoming events, and carousel images.
/// It's fetched from the website and cached locally.
class WebsiteContent {
  /// The daily thought/quote, if available.
  /// Can be null if no thought is available for the day.
  final ThoughtOfTheDay? thoughtOfTheDay;
  
  /// List of upcoming events to highlight on the home screen.
  /// Defaults to an empty list if there are no upcoming events.
  final List<UpcomingEvent> upcomingEvents;
  
  /// URLs of images to display in the image carousel on the home screen.
  /// These are typically photos of recent events or activities.
  final List<String> carouselImages;
  
  /// Timestamp when this content was fetched from the website.
  /// Used to determine if we need to refresh the data.
  final DateTime fetchedAt;

  /// Creates a new WebsiteContent object.
  /// 
  /// All fields except [fetchedAt] are optional and have default values.
  const WebsiteContent({
    this.thoughtOfTheDay,
    this.upcomingEvents = const [],
    this.carouselImages = const [],
    required this.fetchedAt,
  });

  /// Converts this WebsiteContent to JSON format for local storage.
  /// 
  /// Converts nested objects (ThoughtOfTheDay, UpcomingEvent) to JSON
  /// using their respective toJson() methods.
  Map<String, dynamic> toJson() => {
    'thoughtOfTheDay': thoughtOfTheDay?.toJson(),
    'upcomingEvents': upcomingEvents.map((e) => e.toJson()).toList(),
    'carouselImages': carouselImages,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  /// Creates a WebsiteContent from JSON data.
  /// 
  /// Reconstructs all nested objects from their JSON representations.
  /// Handles missing or invalid data gracefully with default values.
  factory WebsiteContent.fromJson(Map<String, dynamic> json) => WebsiteContent(
    // Convert thoughtOfTheDay from JSON if it exists, otherwise null
    thoughtOfTheDay: json['thoughtOfTheDay'] != null
        ? ThoughtOfTheDay.fromJson(
            Map<String, dynamic>.from(json['thoughtOfTheDay'] as Map),
          )
        : null,
    // Convert each upcoming event from JSON to UpcomingEvent object
    upcomingEvents: (json['upcomingEvents'] as List<dynamic>? ?? [])
        .map((e) => UpcomingEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    // Convert image URLs from JSON, filtering out any empty strings
    carouselImages: (json['carouselImages'] as List<dynamic>? ?? [])
        .map((e) => e as String? ?? '')
        .where((e) => e.isNotEmpty)
        .toList(),
    // Parse the fetchedAt timestamp, or use epoch zero if invalid
    fetchedAt:
        DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// Contains all content for the donations screen.
/// 
/// This class stores information about different donation methods available:
/// Zelle, check, PayPal, credit card, and matching grants. Each method
/// has its own instructions, URLs, and other relevant information.
class DonateContent {
  /// Introductory paragraphs explaining the donation process.
  /// Usually displayed at the top of the donations screen.
  final List<String> introParagraphs;
  
  /// Email address for Zelle donations.
  final String? zelleEmail;
  
  /// Instructions on how to donate using Zelle.
  final String? zelleInstruction;
  
  /// URL of the QR code image for Zelle donations.
  final String? zelleQrImageUrl;
  
  /// Instructions on how to donate by check.
  final String? checkInstruction;
  
  /// Mailing address where checks should be sent.
  /// Each line is a separate string in the list.
  final List<String> checkMailingAddress;
  
  /// Instructions for PayPal Giving donations.
  final String? paypalGivingInstruction;
  
  /// URL to the PayPal Giving page.
  final String? paypalGivingUrl;
  
  /// Additional notes about PayPal Giving donations.
  final String? paypalGivingNote;
  
  /// Instructions for credit card donations.
  final String? creditCardInstruction;
  
  /// URL to the credit card donation page.
  final String? creditCardUrl;
  
  /// Additional notes about credit card donations.
  final String? creditCardNote;
  
  /// Instructions about employer matching grants.
  final String? matchingGrantInstruction;
  
  /// URL to the matching grant form.
  final String? matchingFormUrl;
  
  /// Timestamp when this donation content was fetched from the website.
  final DateTime fetchedAt;

  /// Creates a new DonateContent object.
  /// 
  /// Most fields are optional since not all donation methods may be available.
  /// Only [fetchedAt] is required to track when the data was last updated.
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

  /// Converts this DonateContent to JSON format for storage.
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

  /// Creates a DonateContent from JSON data.
  /// 
  /// Filters out any empty strings from list fields to ensure clean data.
  factory DonateContent.fromJson(Map<String, dynamic> json) => DonateContent(
        // Convert intro paragraphs, filtering out empty strings
        introParagraphs: (json['introParagraphs'] as List<dynamic>? ?? [])
            .map((e) => e as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList(),
        zelleEmail: json['zelleEmail'] as String?,
        zelleInstruction: json['zelleInstruction'] as String?,
        zelleQrImageUrl: json['zelleQrImageUrl'] as String?,
        checkInstruction: json['checkInstruction'] as String?,
        // Convert mailing address lines, filtering out empty strings
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
        // Parse the timestamp, or use epoch zero if invalid
        fetchedAt:
            DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Represents information about a section of curricular classes.
/// 
/// This could be for "Youngsters" or "Adults" sections, each with
/// their own title, schedule, and description.
class CurricularClassesSection {
  /// The title of this section (e.g., "Youngsters Classes", "Adults Classes").
  final String title;
  
  /// The class schedule (e.g., "Monday - Friday, 4:00 PM - 6:00 PM").
  final String schedule;
  
  /// A detailed description of what this section offers.
  final String description;

  /// Creates a new CurricularClassesSection.
  /// 
  /// All fields are required.
  const CurricularClassesSection({
    required this.title,
    required this.schedule,
    required this.description,
  });
}

/// Contains all content for the curricular classes screen.
/// 
/// This includes information about both youngsters and adults classes,
/// plus a thumbnail image to display.
class CurricularClassesContent {
  /// Information about the youngsters classes section.
  final CurricularClassesSection youngstersSection;
  
  /// Information about the adults classes section.
  final CurricularClassesSection adultsSection;
  
  /// URL of the thumbnail image to display for curricular classes.
  final String thumbnailUrl;

  /// Creates a new CurricularClassesContent.
  /// 
  /// All fields are required.
  const CurricularClassesContent({
    required this.youngstersSection,
    required this.adultsSection,
    required this.thumbnailUrl,
  });
}

/// Represents information about a music class section.
/// 
/// This could be for "Vocal" or "Tabla" classes, each with its own
/// details including teachers, schedule, and optional registration form.
class MusicClassSection {
  /// The title of this music class section (e.g., "Vocal Classes", "Tabla Classes").
  final String title;
  
  /// Names of the teachers for this class.
  final String teachers;
  
  /// The class schedule.
  final String schedule;
  
  /// A detailed description of the class.
  final String description;
  
  /// Optional URL to a registration form for this class.
  /// Can be null if no form is available.
  final String? formUrl;

  /// Creates a new MusicClassSection.
  /// 
  /// [title], [teachers], [schedule], and [description] are required.
  /// [formUrl] is optional.
  const MusicClassSection({
    required this.title,
    required this.teachers,
    required this.schedule,
    required this.description,
    this.formUrl,
  });
}

/// Contains all content for the music classes screen.
/// 
/// This includes information about both vocal and tabla classes,
/// plus thumbnail images for each.
class MusicClassesContent {
  /// Information about the vocal classes section.
  final MusicClassSection vocalSection;
  
  /// Information about the tabla classes section.
  final MusicClassSection tablaSection;
  
  /// URL of the thumbnail image for vocal classes.
  final String vocalThumbnailUrl;
  
  /// URL of the thumbnail image for tabla classes.
  final String tablaThumbnailUrl;

  /// Creates a new MusicClassesContent.
  /// 
  /// All fields are required.
  const MusicClassesContent({
    required this.vocalSection,
    required this.tablaSection,
    required this.vocalThumbnailUrl,
    required this.tablaThumbnailUrl,
  });
}

/// Contains content for the summer camp information screen.
/// 
/// Stores the title, description, and thumbnail image for summer camp details.
class SummerCampContent {
  /// The title of the summer camp program.
  final String title;
  
  /// A detailed description of the summer camp.
  final String description;
  
  /// URL of the thumbnail image to display for summer camp.
  final String thumbnailUrl;

  /// Creates a new SummerCampContent.
  /// 
  /// All fields are required.
  const SummerCampContent({
    required this.title,
    required this.description,
    required this.thumbnailUrl,
  });
}

/// Represents a single event displayed on the events screen.
/// 
/// Each event has a title, image, and description that are shown
/// to users when they view past or upcoming events.
class Event {
  /// The name or title of the event.
  final String title;
  
  /// URL of the image to display for this event.
  final String imageUrl;
  
  /// Detailed description of the event.
  final String description;

  /// Creates a new Event.
  /// 
  /// All fields are required.
  const Event({
    required this.title,
    required this.imageUrl,
    required this.description,
  });

  /// Converts this Event to JSON format for storage.
  Map<String, dynamic> toJson() => {
    'title': title,
    'imageUrl': imageUrl,
    'description': description,
  };

  /// Creates an Event from JSON data.
  /// 
  /// Uses empty strings as defaults if data is missing.
  factory Event.fromJson(Map<String, dynamic> json) => Event(
    title: json['title'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );
}

/// Container for all events displayed on the events screen.
/// 
/// Holds a list of Event objects and tracks when the data was last fetched.
class EventsContent {
  /// List of all events to display.
  /// Defaults to an empty list if there are no events.
  final List<Event> events;
  
  /// Timestamp when this events data was fetched from the website.
  final DateTime fetchedAt;

  /// Creates a new EventsContent.
  /// 
  /// [events] defaults to an empty list, [fetchedAt] is required.
  const EventsContent({this.events = const [], required this.fetchedAt});

  /// Converts this EventsContent to JSON format for storage.
  /// 
  /// Converts each Event in the list to JSON using its toJson() method.
  Map<String, dynamic> toJson() => {
    'events': events.map((e) => e.toJson()).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  /// Creates an EventsContent from JSON data.
  /// 
  /// Reconstructs each Event object from its JSON representation.
  factory EventsContent.fromJson(Map<String, dynamic> json) => EventsContent(
    // Convert each event from JSON to Event object
    events: (json['events'] as List<dynamic>? ?? [])
        .map((e) => Event.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    // Parse the timestamp, or use epoch zero if invalid
    fetchedAt:
        DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// Contains all content for the bookstore information screen.
/// 
/// Stores details about the bookstore including its location, hours,
/// and contact information.
class BookstoreContent {
  /// The title/name of the bookstore.
  final String title;
  
  /// A description of the bookstore and what it offers.
  final String about;
  
  /// The bookstore's address, with each line as a separate string.
  /// For example: ["123 Main Street", "City, State 12345"]
  final List<String> locationLines;
  
  /// The bookstore's operating hours.
  /// Each string typically represents a day or time range.
  final List<String> hours;
  
  /// Optional email address for contacting the bookstore.
  final String? contactEmail;
  
  /// Timestamp when this bookstore content was fetched from the website.
  final DateTime fetchedAt;

  /// Creates a new BookstoreContent.
  /// 
  /// Most fields are required; only [contactEmail] is optional.
  const BookstoreContent({
    required this.title,
    required this.about,
    required this.locationLines,
    required this.hours,
    this.contactEmail,
    required this.fetchedAt,
  });

  /// Converts this BookstoreContent to JSON format for storage.
  Map<String, dynamic> toJson() => {
    'title': title,
    'about': about,
    'locationLines': locationLines,
    'hours': hours,
    'contactEmail': contactEmail,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  /// Creates a BookstoreContent from JSON data.
  /// 
  /// Filters out any empty strings from list fields to ensure clean data.
  factory BookstoreContent.fromJson(Map<String, dynamic> json) =>
      BookstoreContent(
        title: json['title'] as String? ?? '',
        about: json['about'] as String? ?? '',
        // Convert location lines, filtering out empty strings
        locationLines: (json['locationLines'] as List<dynamic>? ?? [])
            .map((e) => e as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList(),
        // Convert hours, filtering out empty strings
        hours: (json['hours'] as List<dynamic>? ?? [])
            .map((e) => e as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList(),
        contactEmail: json['contactEmail'] as String?,
        // Parse the timestamp, or use epoch zero if invalid
        fetchedAt:
            DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}


/// Contains all content for the admissions screen.
/// 
/// Stores information about the admissions process, including multiple
/// sections of information, form URLs, and mailing address.
class AdmissionsContent {
  /// First section of admissions information.
  /// Can be null if not available.
  final String? sectionI;
  
  /// Second section of admissions information.
  /// Can be null if not available.
  final String? sectionII;
  
  /// Third section of admissions information.
  /// Can be null if not available.
  final String? sectionIII;
  
  /// Fourth section of admissions information.
  /// Can be null if not available.
  final String? sectionIV;
  
  /// URL to the Kindergarten admission form.
  final String? kgFormUrl;
  
  /// URL to an alternate route admission form.
  final String? alternateRouteFormUrl;
  
  /// Mailing address for admissions, with each line as a separate string.
  /// Defaults to an empty list if not provided.
  final List<String> addressLines;
  
  /// Timestamp when this admissions content was fetched from the website.
  final DateTime fetchedAt;

  /// Creates a new AdmissionsContent.
  /// 
  /// Most fields are optional; only [fetchedAt] is required.
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

  /// Converts this AdmissionsContent to JSON format for storage.
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

  /// Creates an AdmissionsContent from JSON data.
  /// 
  /// Filters out any empty strings from the addressLines list.
  factory AdmissionsContent.fromJson(Map<String, dynamic> json) =>
      AdmissionsContent(
        sectionI: json['sectionI'] as String?,
        sectionII: json['sectionII'] as String?,
        sectionIII: json['sectionIII'] as String?,
        sectionIV: json['sectionIV'] as String?,
        kgFormUrl: json['kgFormUrl'] as String?,
        alternateRouteFormUrl: json['alternateRouteFormUrl'] as String?,
        // Convert address lines, filtering out empty strings
        addressLines: (json['addressLines'] as List<dynamic>? ?? [])
            .map((e) => e as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList(),
        // Parse the timestamp, or use epoch zero if invalid
        fetchedAt:
            DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Contains all content for the contact screen.
/// 
/// Stores various contact information including phone, address, email addresses,
/// form URLs, and other important contact-related details.
class ContactContent {
  /// Phone number for contacting the school.
  final String? phone;
  
  /// School address, with each line as a separate string.
  /// Defaults to an empty list if not provided.
  final List<String> addressLines;
  
  /// Instructions for reporting absences and tardiness.
  final String? absenceTardyInstructions;
  
  /// URL to the admissions page or form.
  final String? admissionsUrl;
  
  /// URL to the Monday Scriptural Class registration form.
  final String? mondayScripturalClassFormUrl;
  
  /// URL to the Tabla Class registration form.
  final String? tablaClassFormUrl;
  
  /// Email address for general registration inquiries.
  final String? registrationEmail;
  
  /// Email address for alumni-related inquiries.
  final String? alumniEmail;
  
  /// URL of the hero/banner image to display on the contact screen.
  final String? heroImageUrl;
  
  /// General notice or announcement to display on the contact screen.
  final String? generalNotice;
  
  /// Timestamp when this contact content was fetched from the website.
  final DateTime fetchedAt;

  /// Creates a new ContactContent.
  /// 
  /// Most fields are optional; only [fetchedAt] is required.
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

  /// Converts this ContactContent to JSON format for storage.
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

  /// Creates a ContactContent from JSON data.
  /// 
  /// Filters out any empty strings from the addressLines list.
  factory ContactContent.fromJson(Map<String, dynamic> json) =>
      ContactContent(
        phone: json['phone'] as String?,
        // Convert address lines, filtering out empty strings
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
        // Parse the timestamp, or use epoch zero if invalid
        fetchedAt:
            DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
