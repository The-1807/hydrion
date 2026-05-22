// core/crates/hydrion-time/src/quiet_hours.rs
use chrono::{DateTime, Datelike, Duration, Local, Timelike};

const MINUTES_PER_DAY: u32 = 1440;

#[inline]
fn norm_min(min: u32) -> u32 {
    min % MINUTES_PER_DAY
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct QuietWindow {
    pub start: u32, // inclusive  [start, end)
    pub end: u32,   // exclusive, 0 == 1440 wrap
}

impl QuietWindow {
    pub fn new(start: u32, end: u32) -> Option<Self> {
        let s = norm_min(start);
        let e = norm_min(end);
        if s == e { return None; }
        Some(Self { start: s, end: e })
    }

    #[inline]
    pub fn duration(&self) -> u32 {
        if self.start < self.end {
            self.end - self.start
        } else {
            (MINUTES_PER_DAY - self.start) + self.end
        }
    }

    #[inline]
    pub fn contains(&self, minute: u32) -> bool {
        let m = norm_min(minute);
        if self.start < self.end {
            (m >= self.start) && (m < self.end)
        } else {
            (m >= self.start) || (m < self.end)
        }
    }

    pub fn next_transition_after(&self, minute: u32) -> (u32, Transition) {
        let m = norm_min(minute);
        if self.contains(m) {
            (self.end, Transition::QuietEnds)
        } else {
            // next start is either today or next day (for non-wrapping window), or today for wrapping window
            let next_start = if self.start < self.end {
                if m < self.start { self.start } else { norm_min(self.start + MINUTES_PER_DAY) }
            } else {
                self.start
            };
            (next_start, Transition::QuietStarts)
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Transition {
    QuietStarts,
    QuietEnds,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct QuietHours {
    windows: Vec<QuietWindow>, // normalized, non-overlapping, sorted by start
}

impl QuietHours {
    pub fn empty() -> Self {
        Self { windows: Vec::new() }
    }

    pub fn from_windows(mut windows: Vec<QuietWindow>) -> Self {
        if windows.is_empty() {
            return Self::empty();
        }
        // Expand over-midnight windows into [start,1440) and [0,end)
        let mut segs: Vec<(u32, u32)> = Vec::with_capacity(windows.len() * 2);
        for w in windows.drain(..) {
            if w.start < w.end {
                segs.push((w.start, w.end));
            } else {
                segs.push((w.start, MINUTES_PER_DAY));
                segs.push((0, w.end));
            }
        }
        // Merge overlaps
        segs.sort_unstable_by_key(|s| s.0);
        let mut merged: Vec<(u32, u32)> = Vec::with_capacity(segs.len());
        for (s, e) in segs {
            if let Some(last) = merged.last_mut() {
                if s <= last.1 {
                    if e > last.1 { last.1 = e; }
                } else {
                    merged.push((s, e));
                }
            } else {
                merged.push((s, e));
            }
        }
        // Rejoin [last,1440) + [0,first] into a single wrapping window if contiguous
        let mut out: Vec<QuietWindow> = Vec::new();
        if merged.len() >= 2 && merged[0].0 == 0 {
            if let Some(&(ls, le)) = merged.last() {
                if le == MINUTES_PER_DAY {
                    out.push(QuietWindow { start: ls, end: 0 });
                    for (idx, (s, e)) in merged.iter().enumerate() {
                        if idx == 0 || idx == merged.len() - 1 { continue; }
                        out.push(QuietWindow { start: *s, end: e % MINUTES_PER_DAY });
                    }
                    out.sort_by_key(|w| w.start);
                    return Self { windows: out };
                }
            }
        }
        for (s, e) in merged {
            out.push(QuietWindow { start: s, end: e % MINUTES_PER_DAY });
        }
        out.sort_by_key(|w| w.start);
        Self { windows: out }
    }

    pub fn single(start_minutes: u32, end_minutes: u32) -> Self {
        match QuietWindow::new(start_minutes, end_minutes) {
            Some(w) => Self::from_windows(vec![w]),
            None => Self::empty(),
        }
    }

    #[inline]
    pub fn is_quiet_minute(&self, minute: u32) -> bool {
        self.windows.iter().any(|w| w.contains(minute))
    }

    pub fn is_quiet_now_local(&self) -> bool {
        let now = Local::now();
        let m = now.hour() * 60 + now.minute();
        self.is_quiet_minute(m)
    }

    pub fn coverage_ratio(&self) -> f64 {
        let total: u32 = self.windows.iter().map(|w| w.duration()).sum();
        (total as f64) / (MINUTES_PER_DAY as f64)
    }

    pub fn remaining_quiet_minutes(&self, minute: u32) -> Option<u32> {
        if !self.is_quiet_minute(minute) {
            return None;
        }
        let m = norm_min(minute);
        for w in &self.windows {
            if w.contains(m) {
                let e = w.end;
                return Some(if m <= e { e - m } else { (MINUTES_PER_DAY - m) + e });
            }
        }
        None
    }

    pub fn next_transition(&self, minute: u32) -> Option<(u32, Transition)> {
        if self.windows.is_empty() { return None; }
        let m = norm_min(minute);
        let mut best: Option<(u32, Transition, u32)> = None;
        for w in &self.windows {
            let (cand, kind) = w.next_transition_after(m);
            let delta = if cand >= m { cand - m } else { (MINUTES_PER_DAY - m) + cand };
            if best.map(|b| delta < b.2).unwrap_or(true) {
                best = Some((cand, kind, delta));
            }
        }
        best.map(|(c, k, _)| (c, k))
    }

    pub fn next_allowed_minute(&self, minute: u32) -> u32 {
        if !self.is_quiet_minute(minute) {
            return norm_min(minute);
        }
        if let Some((at, Transition::QuietEnds)) = self.next_transition(minute) {
            return at;
        }
        norm_min(minute)
    }

    pub fn windows(&self) -> &[QuietWindow] {
        &self.windows
    }
}

pub fn default_quiet_hours_22_06() -> QuietHours {
    QuietHours::single(22 * 60, 6 * 60)
}

pub fn next_allowed_instant_local(policy: &QuietHours) -> DateTime<Local> {
    let now = Local::now();
    let m = now.hour() * 60 + now.minute();
    let next_min = policy.next_allowed_minute(m);
    if next_min == m { return now; }

    let midnight = now.date_naive().and_hms_opt(0, 0, 0).unwrap();
    let base = Local.from_local_datetime(&midnight).earliest().unwrap();
    let delta_min = if next_min > m { next_min - m } else { (MINUTES_PER_DAY - m) + next_min };
    base + Duration::minutes((m + delta_min) as i64)
}

#[inline]
pub fn local_minutes_past_midnight_now() -> u32 {
    let now = Local::now();
    now.hour() * 60 + now.minute()
}
