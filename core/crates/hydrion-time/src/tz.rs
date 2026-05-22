///core\crates\hydrion-time\src\tz.rs

/// Returns the current time in minutes past midnight (0 to 1439) in the local timezone.
/// deriving Age, Zodiac sign, menstral cycle and even puberty through D.O.Ob

use chrono::{Datelike, NaiveDate, TimeZone, Timelike, Utc, Local, DateTime};

/// for the zodiac sign calculation
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ZodiacSign {
    Aries, Taurus, Gemini, Cancer, Leo, Virgo,
    Libra, Scorpio, Sagittarius, Capricorn, Aquarius, Pisces,
}

/// gender
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Sex {
    Female,
    Male,
    Unspecified,
}

/// Pubverty stage
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PubertyStage {
    Prepubertal,
    PubertalWindow,
    Postpubertal,
    Unknown,
}

/// Menstrual cycle phase
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MenstrualPhase {
    Menstruation,
    Follicular,
    OvulationWindow,
    Luteal,
}

/// past midnight
#[inline]
pub fn local_minutes_past_midnight() -> u32 {
    let now = Local::now();
    now.hour() * 60 + now.minute()
}

pub fn minutes_past_midnight_from_timestamp_local(ts_ms: i64) -> Option<u32> {
    let dt_utc = Utc.timestamp_millis_opt(ts_ms).single()?;
    let dt_local: DateTime<Local> = DateTime::from(dt_utc);
    Some(dt_local.hour() * 60 + dt_local.minute())
}

pub fn age_from_dob_ts(dob_ts_ms: i64) -> Option<u32> {
    let dob = Utc.timestamp_millis_opt(dob_ts_ms).single()?;
    let now = Utc::now();
    if dob > now { return None; }

    let (bm, bd) = (dob.month(), dob.day());
    let birthday_date = NaiveDate::from_ymd_opt(now.year(), bm, bd)
        .or_else(|| if bm == 2 && bd == 29 { NaiveDate::from_ymd_opt(now.year(), 2, 28) } else { None })?;
    let birthday_this_year = birthday_date.and_hms_opt(0, 0, 0).map(|n| DateTime::<Utc>::from_utc(n, Utc))?;

    let mut age = now.year() - dob.year();
    if now < birthday_this_year { age -= 1; }
    if age < 0 { return None; }
    Some(age as u32)
}

pub fn zodiac_from_dob_ts(dob_ts_ms: i64) -> Option<ZodiacSign> {
    let dt = Utc.timestamp_millis_opt(dob_ts_ms).single()?;
    Some(zodiac_from_month_day(dt.month(), dt.day()))
}

pub fn zodiac_from_month_day(month: u32, day: u32) -> ZodiacSign {
    match (month, day) {
        (3, 21..=31) | (4, 1..=19) => ZodiacSign::Aries,
        (4, 20..=30) | (5, 1..=20) => ZodiacSign::Taurus,
        (5, 21..=31) | (6, 1..=20) => ZodiacSign::Gemini,
        (6, 21..=30) | (7, 1..=22) => ZodiacSign::Cancer,
        (7, 23..=31) | (8, 1..=22) => ZodiacSign::Leo,
        (8, 23..=31) | (9, 1..=22) => ZodiacSign::Virgo,
        (9, 23..=30) | (10, 1..=22) => ZodiacSign::Libra,
        (10, 23..=31) | (11, 1..=21) => ZodiacSign::Scorpio,
        (11, 22..=30) | (12, 1..=21) => ZodiacSign::Sagittarius,
        (12, 22..=31) | (1, 1..=19) => ZodiacSign::Capricorn,
        (1, 20..=31) | (2, 1..=18) => ZodiacSign::Aquarius,
        _ => ZodiacSign::Pisces, // (2,19..=29) | (3,1..=20)
    }
}

pub fn puberty_stage_from_dob(dob_ts_ms: i64, sex: Sex) -> Option<PubertyStage> {
    let age = age_from_dob_ts(dob_ts_ms)?;
    let stage = match sex {
        Sex::Female => {
            if age < 8 { PubertyStage::Prepubertal }
            else if age <= 15 { PubertyStage::PubertalWindow }
            else { PubertyStage::Postpubertal }
        }
        Sex::Male => {
            if age < 9 { PubertyStage::Prepubertal }
            else if age <= 16 { PubertyStage::PubertalWindow }
            else { PubertyStage::Postpubertal }
        }
        Sex::Unspecified => PubertyStage::Unknown,
    };
    Some(stage)
}

pub struct CycleEstimate {
    pub day_in_cycle: u32,
    pub cycle_length_days: u32,
    pub phase: MenstrualPhase,
}

/// Requires last menstrual period date and average cycle length. DOB alone is not sufficient.
pub fn menstrual_cycle_phase(
    last_menstruation_ymd: Option<(i32, u32, u32)>,
    avg_cycle_length_days: Option<u32>,
    today_utc: Option<DateTime<Utc>>,
) -> Option<CycleEstimate> {
    let (y, m, d) = last_menstruation_ymd?;
    let cycle_len = avg_cycle_length_days?;
    if cycle_len < 20 || cycle_len > 60 { return None; }

    let lmp = NaiveDate::from_ymd_opt(y, m, d)?.and_hms_opt(0, 0, 0)?;
    let today = today_utc.unwrap_or_else(Utc::now);
    if today < DateTime::<Utc>::from_utc(lmp, Utc) { return None; }

    let days_since = (today.date_naive() - NaiveDate::from_ymd_opt(y, m, d)?).num_days() as u32;
    let day_in_cycle = (days_since % cycle_len) + 1;

    let phase = if day_in_cycle <= 5 {
        MenstrualPhase::Menstruation
    } else if day_in_cycle <= (cycle_len.saturating_sub(14)).max(6) {
        MenstrualPhase::Follicular
    } else if (cycle_len >= 12) && (day_in_cycle >= cycle_len - 14) && (day_in_cycle <= cycle_len - 12) {
        MenstrualPhase::OvulationWindow
    } else {
        MenstrualPhase::Luteal
    };

    Some(CycleEstimate {
        day_in_cycle,
        cycle_length_days: cycle_len,
        phase,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_local_minutes_bounds() {
        let m = local_minutes_past_midnight();
        assert!(m < 1440);
    }

    #[test]
    fn test_age_non_future() {
        let future = Utc::now().timestamp_millis() + 86_400_000;
        assert_eq!(age_from_dob_ts(future), None);
    }

    #[test]
    fn test_zodiac_mapping() {
        assert_eq!(zodiac_from_month_day(3, 21), ZodiacSign::Aries);
        assert_eq!(zodiac_from_month_day(12, 25), ZodiacSign::Capricorn);
        assert_eq!(zodiac_from_month_day(2, 19), ZodiacSign::Pisces);
    }

    #[test]
    fn test_puberty_rules() {
        assert_eq!(puberty_stage_from_dob(Utc::now().with_year(Utc::now().year() - 7).unwrap().timestamp_millis(), Sex::Female), Some(PubertyStage::Prepubertal));
        assert_eq!(puberty_stage_from_dob(Utc::now().with_year(Utc::now().year() - 20).unwrap().timestamp_millis(), Sex::Male), Some(PubertyStage::Postpubertal));
        assert_eq!(puberty_stage_from_dob(Utc::now().timestamp_millis(), Sex::Unspecified), Some(PubertyStage::Unknown));
    }

    #[test]
    fn test_cycle_needs_inputs() {
        assert!(menstrual_cycle_phase(None, Some(28), None).is_none());
        assert!(menstrual_cycle_phase(Some((2025, 1, 1)), None, None).is_none());
    }
}
