# SCHEMA — class schedule 2026-2027 (both days)

Field contract for the structured Vivekananda Vidyapith Sunday School timetable. Two files carry the
same schema, one per teaching day:

| Day | Structured data (canonical) | Flat | Readable |
|---|---|---|---|
| Saturday | `saturday-school-schedule-2026-2027.json` | `.csv` | `.md` |
| Sunday | `sunday-school-schedule-2026-2027.json` | `.csv` | `.md` |

Everything here comes from a printed handout; nothing is inferred. Where a value could not be read
with confidence it is flagged in `uncertainties[]` rather than guessed. Verbatim per-sheet reads live
in the transcription sidecars.

**The four rules under "Reading the data" are the ones that actually change the UI. Read those even
if you skim the rest.**

## Top level

| Field | Type | Meaning |
|---|---|---|
| `schema_version` | string | `"2.0"` (the Sunday file was written as `"1.0"` and is compatible) |
| `day` | string | `"Saturday"` \| `"Sunday"` |
| `document` | object | Title, organisation, program, academic year, revision, `day`, `periods_per_session` (always 4), `structure` (prose) |
| `legend` | object | Maps the printed symbols `*`, `(-)`, `((--))` to their meaning |
| `clusters` | array | The four clusters, in roman-numeral order I, II, III, IV |
| `source` | object | Email subject/from/date/message id, the attachment filenames with dimensions, what each photo contains, and how the text was extracted |
| `uncertainties` | array | Every reading that is not fully confirmed, with `where` / `printed` / `issue` / `impact` |

## `clusters[]`

| Field | Type | Meaning |
|---|---|---|
| `id` | string | `"I"` \| `"II"` \| `"III"` \| `"IV"` |
| `sheet` | integer | Which photographed sheet holds this cluster (1 or 2) |
| `page_number` | integer | The page number printed on the sheet: I=1, II=2, III=3, IV=4 |
| `page_in_sheet` | string | `"top"` or `"bottom"` — where on the sheet the cluster is printed |
| `title_raw` | string | Cluster heading as printed, e.g. `"SAT Cluster I"` |
| `grades` | array of string | Grades in this cluster |
| `celebrations_raw` | string | The celebration line exactly as printed |
| `celebrations` | array of string | The same line split into items |
| `prayer_assembly` | object | The prayer/assembly/snack-break row text, keyed by section code or `"all"` |
| `periods_split_semesters` | array of int | *(Saturday only)* period numbers split into two semester halves. Present on Cluster III: `[4]` |
| `groups` | array | One entry per grade |

> **Grade counts differ by cluster and by day.** Clusters I–III hold three grades; **Cluster IV holds
> four** (9, 10, 11, 12). Never hard-code three, and never build a fixed 3-row layout.

## `clusters[].groups[]`

| Field | Type | Meaning |
|---|---|---|
| `grade` | string | Grade as printed: `"KG"`, `"1"` … `"12"` |
| `grade_label` | string | Grade with its section letter — `"3B"`, `"9B"`, `"KG A"`, `"1A"` — the unit most people mean by "grade" |
| `header_raw` | string | The grade header exactly as printed, e.g. `"(17+1) Grade 5B"` |
| `class_size` | integer \| null | The number in the header. Saturday's Cluster I prints it to the left of the section code (`"17+  KG A  KG Hall"`) |
| `class_size_note` | string \| null | The `+N` part and the header as printed, e.g. `"+1 (printed \"(17+1)  5A  Room 204 …\")"` |
| `room` | string | Room as printed |
| `room_note` | string \| null | Breakout rooms and period-specific room notes |
| `sections` | array of `{code, room}` | Section code as printed (`3B1`, `9B`, `1A`) and the room for it |
| `snack_break` | boolean | Present and `true` where the header row prints *Snack Break* |
| `periods` | array | Four entries, `period` 1–4 |

## `clusters[].groups[].periods[]`

| Field | Type | Meaning |
|---|---|---|
| `period` | integer | 1–4 |
| `subject_scope` | string | `"section"` — each cell prints its own subject. `"grade"` — the subject is printed once across the whole grade group |
| `subject` | string | Present when `subject_scope == "grade"`; otherwise on the cell |
| `subject_detail` | string | Present when `subject_scope == "grade"` and the cell carries a description |
| `merged` | boolean | `true` when one printed cell spans every section of the grade (so the teacher list is identical across those cells, not independently printed) |
| `cells` | array | One entry per section, always in printed left-to-right order |

**Saturday is `"section"` throughout** — every grade prints its own subject in every period. The
`"grade"` / `merged` machinery exists for the Sunday sheets (Sunday Clusters III and IV).

## `…periods[].cells[]`

| Field | Type | Meaning |
|---|---|---|
| `section` | string | Section code this cell belongs to (may be null on Saturday, where section == `grade_label`) |
| `subject` | string | Period/subject name as printed, when the subject is per-section |
| `subject_detail` | string | Description that follows the subject name in the same printed line |
| `activity_raw` | string | The subject line exactly as printed (subject + description, unsplit) |
| `teachers_raw` | string | **Authoritative.** The teacher list exactly as printed |
| `teachers` | array | Best-effort split of `teachers_raw` — see below |
| `merged_with` | string | Set on cells whose printed text was read from an adjacent merged cell |
| `halves` | array | *(Saturday, Cluster III period 4 only)* two entries, `Semester 1` and `Semester 2`, each shaped like a cell: `label`, `subject`, `subject_detail`, `activity_raw`, `teachers_raw`, `teachers` |
| `flags` | array of string | Free-text notes about this specific cell |

## `…cells[].teachers[]`

| Field | Type | Meaning |
|---|---|---|
| `name` | string \| null | Name with the symbols stripped. **Nullable** — the sheet prints `(Uncle)` / `((Uncle))` with no personal name |
| `raw` | string | The printed token, symbols included |
| `multi_cluster` | boolean | Printed `*` — teaches in more than one cluster |
| `attendance` | string \| null | `"attend"` for single parentheses, `"occasional"` for double parentheses |
| `compound` | boolean | The token named more than one teacher (e.g. `Sonali didi / Rushil bhayya`, `Trupti Aunty* and /or Madhuri Aunty*`) — do not treat as one person |
| `note` | string | Anything else worth keeping (trailing punctuation as printed, etc.) |

**`teachers_raw` is authoritative; `teachers` is a convenience split.** The sheets are hand-edited and
several lists run two names together without a comma. When a name matters, parse `teachers_raw`
yourself, or read the transcription sidecar for that sheet.

## Reading the data — the four rules that matter

1. **`subject_scope` decides where the subject lives.** `"section"` → each cell carries its own
   `subject`. `"grade"` → the subject is printed **once for the whole grade group**; read it from
   `period.subject`, never from the cell. (Sunday, Clusters III and IV.)
2. **`period.merged == true` → one teacher list covers every section.** Render it **once**. Do not
   repeat it per section. (Sunday, grade 3 period 3 `Music III`.)
3. **`subject_scope == "grade"` without `merged` → shared subject, separate teacher lists.** One
   subject, then one teacher block per section. The lists are printed independently and may differ —
   do not collapse them and do not assume they are equal. (Sunday, grade 6 period 3 `Sanskrit VI`.)
4. **`teachers_raw` is authoritative.** Render it as printed — symbols, parentheses and all. Never
   tidy a name, never expand an abbreviation, never drop the `*` / `( )` / `(( ))` markers: they
   carry meaning (see `legend`). Where `teachers[].name` is null, that gap is on the source document.

## Invariants worth asserting in code

- `clusters` has exactly 4 entries, ids `I`,`II`,`III`,`IV`; `periods_per_session` is 4.
- Clusters I–III have exactly 3 groups; Cluster IV has exactly 4.
- Every `groups[].periods[]` has exactly 4 entries numbered 1–4.
- For each period, `cells[].section` is the full set of that group's `sections[].code` (on Saturday,
  one section per grade, so exactly one cell per period).
- A period whose number is in `periods_split_semesters` carries `halves` on its cell and **no**
  `subject` / `teachers_raw` at cell level — read them from the halves.
- When `subject_scope == "grade"` and `merged` is absent, the subject is shared but each cell's
  teacher list is independently printed — do **not** deduplicate those cells.
- When `merged == true`, every cell in that period carries the same `teachers_raw` by construction.
- A `room` string can be period-dependent (Sunday: `"Room 109 - Periods 1,2,3; Library - Period 4"`).
  Render it as printed; never present it as one unconditional room.

## Day differences at a glance

| | Saturday | Sunday |
|---|---|---|
| Section letter | **A** for every grade | **B** (KG and 8B have no numeral; I has `KG`, `1B`, `2B`; II–IV use `B1`/`B2` pairs except `8B`, `9B`, `10B`, `11B`, `12B`) |
| Sections per grade | 1 | 1 or 2 |
| `subject_scope` | `"section"` throughout | `"grade"` in Clusters III and IV |
| Period 4 semester split | Cluster III only | not present |
| Periods per session | 4 | 4 |
| Clusters per sheet | 2 (sheet 1 = I + III, sheet 2 = II + IV) | 2 (sheet 1 = I + III, sheet 2 = II + IV) |
