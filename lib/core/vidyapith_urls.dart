/// Shared URL builders for Vidyapith website resources.
///
/// Keeps year-dependent links (like the annual calendar page) in one place
/// so the app does not break when a new calendar year begins.
library;

/// Public Google Calendar ID for Vidyapith Events.
const String vidyapithGoogleCalendarId =
    'c_969f838c47a1a405bb19e4c851229d2d328e0341c832114b005063621493804e@group.calendar.google.com';

/// Builds the Vidyapith yearly calendar page URL.
///
/// Matches the site convention: `/{year}-calendar.html`
/// (e.g. `https://www.vidyapith.org/2026-calendar.html`).
///
/// Pass [now] to freeze the year in tests; defaults to [DateTime.now].
String vidyapithCalendarPageUrl({DateTime? now}) {
  final year = (now ?? DateTime.now()).year;
  return 'https://www.vidyapith.org/$year-calendar.html';
}

/// Public ICS feed for Vidyapith Events (used to populate the in-app calendar).
String get vidyapithGoogleCalendarIcsUrl {
  final encodedId = Uri.encodeComponent(vidyapithGoogleCalendarId);
  return 'https://calendar.google.com/calendar/ical/$encodedId/public/basic.ics';
}

/// Browser URL that adds the Vidyapith Google Calendar to the user's account.
const String vidyapithGoogleCalendarSyncUrl =
    'https://calendar.google.com/calendar/u/1?cid=Y185NjlmODM4YzQ3YTFhNDA1YmIxOWU0Yzg1MTIyOWQyZDMyOGUwMzQxYzgzMjExNGIwMDUwNjM2MjE0OTM4MDRlQGdyb3VwLmNhbGVuZGFyLmdvb2dsZS5jb20';
