# SCHEMA — sunday-school-schedule-2026-2027.json

Field contract for the structured Sunday School timetable. Everything here comes from a printed
handout; nothing is inferred. Where a value could not be read with confidence it is flagged in
`uncertainties[]` rather than guessed.

## Top level

| Field | Type | Meaning |
|---|---|---|
| `schema_version` | string | `"1.0"` |
| `document` | object | Title, school, program, academic year, revision, `structure` (prose), `periods_per_session` (always 4) |
| `legend` | object | Maps the printed symbols `*`, `(-)`, `((--))` to their meaning |
| `clusters` | array | The four clusters, in roman-numeral order I, II, III, IV |
| `source` | object | Email subject/from/date/message id, the two attachment filenames with dimensions, what each photo contains, and how the text was extracted |
| `uncertainties` | array | Every reading that is not fully confirmed, with `where` / `printed` / `issue` / `impact` |

## `clusters[]`

| Field | Type | Meaning |
|---|---|---|
| `id` | string | `"I"` \| `"II"` \| `"III"` \| `"IV"` |
| `sheet` | integer | Which photographed sheet holds this cluster (1 or 2) |
| `page_number` | integer | The page number printed on the sheet: I=1, II=2, III=3, IV=4 |
| `page_in_sheet` | string | `"top"` or `"bottom"` — where on the sheet the cluster is printed |
| `grades` | array of string | Grades in this cluster |
| `celebrations_raw` | string | The celebration line exactly as printed |
| `celebrations` | array of string | The same line split into items |
| `prayer_assembly` | object | The prayer/assembly/snack-break row text, keyed by section code or `"all"` |
| `groups` | array | One entry per grade |

## `clusters[].groups[]`

| Field | Type | Meaning |
|---|---|---|
| `grade` | string | Grade label as printed: `"KG"`, `"1"` … `"12"` |
| `grade_label` | string | Grade with its section letter — `"3B"`, `"KG"`, `"9B"` — the unit most people mean by "grade" |
| `header_raw` | string | The grade header exactly as printed, e.g. `"(17+1) Grade 5B"` or `"KG (TBD) (20)"` |
| `class_size` | integer | The number in the first set of parentheses in the header |
| `class_size_note` | string \| null | The `+N` part and the header as printed, e.g. `"+1 (printed \"(17+1) Grade 5B\")"` |
| `sections` | array of `{code, room}` | Section code as printed (`3B1`, `9B`) and the room for it |
| `room_note` | string | Absent unless the header carries one (e.g. breakout rooms, library periods) |
| `snack_break` | boolean | Present and `true` where the header row prints *Snack Break* |
| `periods` | array | Four entries, `period` 1–4 |

## `clusters[].groups[].periods[]`

| Field | Type | Meaning |
|---|---|---|
| `period` | integer | 1–4 |
| `subject_scope` | string | `"section"` — each cell prints its own subject. `"grade"` — the subject is printed once across the whole grade group (the cells in rows below repeat it for convenience) |
| `subject` | string | Present when `subject_scope == "grade"`; otherwise on the cell |
| `subject_detail` | string | Present when `subject_scope == "grade"` and the cell carries a description |
| `merged` | boolean | `true` when one printed cell spans every section of the grade (so the teacher list is identical across those cells, not independently printed) |
| `cells` | array | One entry per section, always in printed left-to-right order |

## `…periods[].cells[]`

| Field | Type | Meaning |
|---|---|---|
| `section` | string | Section code this cell belongs to |
| `subject` | string | Period/subject name as printed, when the subject is per-section |
| `subject_detail` | string | Description that follows the subject name in the same printed line |
| `activity_raw` | string | The subject line exactly as printed (subject + description, unsplit) |
| `teachers_raw` | string | **Authoritative.** The teacher list exactly as printed |
| `teachers` | array | Best-effort split of `teachers_raw` — see below |
| `merged_with` | string | Set on cells whose printed text was read from an adjacent merged cell |
| `flags` | array of string | Free-text notes about this specific cell |

## `…cells[].teachers[]`

| Field | Type | Meaning |
|---|---|---|
| `name` | string | Name with the symbols stripped |
| `raw` | string | The printed token, symbols included |
| `multi_cluster` | boolean | Printed `*` — teaches in more than one cluster |
| `attendance` | string | `"attend"` for single parentheses, `"occasional"` for double parentheses |
| `compound` | boolean | The token named more than one teacher (e.g. `Trupti Aunty* and /or Madhuri Aunty*`) — do not treat as one person |
| `note` | string | Anything else worth keeping (trailing punctuation as printed, etc.) |

**`teachers_raw` is authoritative; `teachers` is a convenience split.** The sheet is hand-edited and
several lists run two names together without a comma. When a name matters, parse `teachers_raw`
yourself, or read the transcription sidecar for that sheet.

## Invariants worth asserting in code

- `clusters` has exactly 4 entries, ids `I`,`II`,`III`,`IV`; `periods_per_session` is 4.
- Every `groups[].periods[]` has exactly 4 entries numbered 1–4.
- For each period, `cells[].section` is the full set of that group's `sections[].code`.
- When `subject_scope == "grade"` and `merged` is absent, the subject is shared but each cell's
  teacher list is independently printed — do **not** deduplicate those cells.
- When `merged == true`, every cell in that period carries the same `teachers_raw` by construction.
