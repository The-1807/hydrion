# Hydrion Tester Bible

## Hydration PDF Reports

Reports are opened from Analytics > Hydration reports. Generation is local and
export requires an explicit user action. Record platform results independently.

### Acceptance Scenarios

- [ ] Weekly selection immediately shows today and the previous six local dates.
- [ ] Monthly selection immediately shows the rolling calendar-month boundary.
- [ ] Quarterly selection immediately shows the rolling three-month boundary.
- [ ] Yearly selection immediately shows the rolling twelve-month boundary.
- [ ] March 31 and leap-year dates follow the clamp-then-next-day rule.
- [ ] Rapid switching leaves dates, metrics, graph and PDF on the last selection.
- [ ] Exact inclusive boundaries match in the preview and exported PDF.
- [ ] Missing dates use the missing marker and are not displayed as zero intake.
- [ ] Known target changes appear only from their effective dates.
- [ ] Unavailable historical targets are labeled unavailable, never backfilled.
- [ ] Daily, weekly and monthly graph aggregates reconcile with report totals.
- [ ] Graph bars, target markers, missing markers, axes, unit and legend remain understandable without color.
- [ ] EN, ES and FR graph labels remain readable without clipping.
- [ ] Light and dark preview themes keep adequate graph contrast.
- [ ] Maximum yearly history generates without freezing or excessive memory use.
- [ ] Editing, moving or deleting entries updates both preview and PDF.
- [ ] Milliliter and fluid-ounce display values remain consistent.
- [ ] Empty and in-progress periods are clearly identified.
- [ ] Navigating away during generation produces no late update or success message.
- [ ] Dismissing sharing produces no success message and permits another attempt.
- [ ] Export failure shows a recoverable error and preserves hydration records.
- [ ] Repeated attempts leave no duplicate or abandoned temporary report files.
- [ ] Android can open, save and share the PDF through system targets.
- [ ] iOS can open, save and share the PDF through system targets.
- [ ] PDF pages have readable tables, headers, footers and page numbers.

### Platform Gates

Android and iOS opening, saving and sharing are physical acceptance gates. A
passing Dart/widget suite or web build does not certify a system share target.
