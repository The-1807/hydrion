# Hydration Report Architecture

## Period Semantics

Every report ends on the current local calendar date. Weekly reports include
today and the previous six dates. Month-based reports first subtract one, three,
or twelve calendar months while clamping the day to the destination month's last
valid day, then begin on the following local date. For example, March 31 minus
one month clamps to February 28 (or 29), so the inclusive monthly window begins
March 1 and ends March 31. Calendar dates are advanced by constructing the next
local date, never by adding 24-hour durations across daylight-saving changes.

## Canonical Flow

`HydrationReportPeriod` calculates the window. `HydrationReportCalculator`
filters canonical stored milliliter events, aggregates daily records, applies
known dated target changes, and builds `HydrationReportGraph`. The screen preview
and PDF renderer consume that same immutable report model. Daily points are used
for weekly/monthly reports, seven-day buckets for quarterly reports, and calendar
month buckets for yearly reports. A bucket with no tracked record remains null.

## Dependency Decision

No chart package was added. Flutter `CustomPainter` renders the on-screen time
series, while the existing `pdf` widget primitives render the PDF equivalent.
This avoids another plugin, transitive dependency set, license, and Android
toolchain compatibility surface. PDF generation uses bundled Apache-2.0 Roboto
fonts and performs no network font or asset fetch.

## Privacy And Lifecycle

Hydration calculations and PDF rendering remain on-device. The filename is the
generic `hydrion-report.pdf`; identity and hydration values are not logged or
placed in temporary paths. PDF metadata contains generic Hydrion report labels.
Hydrion does not create a persistent report archive. The share plugin owns any
transient cache copy and the operating system manages that cache. Export requires
an explicit tap, concurrent taps are suppressed, dismissal is not success, and
mounted checks prevent UI updates after navigation or disposal.

Legacy versions did not persist complete target history or explicit zero-intake
events. Unknown target dates remain unavailable; the current target is never
applied retroactively. Those storage capabilities remain separate open work.
