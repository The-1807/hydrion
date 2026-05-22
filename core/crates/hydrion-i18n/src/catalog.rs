// core/crates/hydrion-i18n/src/catalog.rs
use crate::error::I18nError;
use serde_json::Value;
use std::borrow::Cow;
use std::collections::HashMap;
use std::fs;
use std::io::ErrorKind;
use std::path::{Path, PathBuf};
use std::sync::Arc;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Language {
    En, Fr, Es, Ar, De, Pt, Hi, Zh, Ja, Ko, It, Nl, Sv, Tr, Pl, Id, Th, Vi, El, He, Uk, Ro, Cs, Hu, Fi, Da, No, Sk,
    Other(Cow<'static, str>),
}

impl Language {
    #[inline]
    pub fn code(&self) -> &str {
        match self {
            Language::En => "en", Language::Fr => "fr", Language::Es => "es", Language::Ar => "ar",
            Language::De => "de", Language::Pt => "pt", Language::Hi => "hi", Language::Zh => "zh",
            Language::Ja => "ja", Language::Ko => "ko", Language::It => "it", Language::Nl => "nl",
            Language::Sv => "sv", Language::Tr => "tr", Language::Pl => "pl", Language::Id => "id",
            Language::Th => "th", Language::Vi => "vi", Language::El => "el", Language::He => "he",
            Language::Uk => "uk", Language::Ro => "ro", Language::Cs => "cs", Language::Hu => "hu",
            Language::Fi => "fi", Language::Da => "da", Language::No => "no", Language::Sk => "sk",
            Language::Other(c) => c.as_ref(),
        }
    }

    pub fn from_locale(locale: &str) -> Self {
        let code = locale.split(['-', '_']).next().unwrap_or(locale).to_lowercase();
        match code.as_str() {
            "en" => Language::En, "fr" => Language::Fr, "es" => Language::Es, "ar" => Language::Ar,
            "de" => Language::De, "pt" => Language::Pt, "hi" => Language::Hi, "zh" => Language::Zh,
            "ja" => Language::Ja, "ko" => Language::Ko, "it" => Language::It, "nl" => Language::Nl,
            "sv" => Language::Sv, "tr" => Language::Tr, "pl" => Language::Pl, "id" => Language::Id,
            "th" => Language::Th, "vi" => Language::Vi, "el" => Language::El, "he" => Language::He,
            "uk" => Language::Uk, "ro" => Language::Ro, "cs" => Language::Cs, "hu" => Language::Hu,
            "fi" => Language::Fi, "da" => Language::Da, "no" => Language::No, "sk" => Language::Sk,
            other => Language::Other(Cow::Owned(other.to_string())),
        }
    }

    pub fn detect() -> Self {
        #[cfg(feature = "locale-detect")]
        {
            sys_locale::current()
                .map(|l| Language::from_locale(&l))
                .unwrap_or(Language::En)
        }
        #[cfg(not(feature = "locale-detect"))]
        {
            Language::En
        }
    }
}

#[derive(Debug, Clone)]
pub struct LocalizationCatalog {
    language: Language,
    translations: Arc<HashMap<String, String>>,
    size: usize,
}

impl LocalizationCatalog {
    pub fn load(language: Language, base_dir: &Path) -> Result<Self, I18nError> {
        let path = base_dir.join(format!("{}.json", language.code()));
        let contents = fs::read_to_string(&path).map_err(|e| match e.kind() {
            ErrorKind::NotFound => I18nError::FileNotFound(path.display().to_string()),
            _ => I18nError::Io(e),
        })?;
        let json: Value = serde_json::from_str(&contents)?;
        let translations = flatten_json(&json)?;
        let size = translations.len();
        Ok(Self {
            language,
            translations: Arc::new(translations),
            size,
        })
    }

    #[inline]
    pub fn get(&self, key: impl AsRef<str>) -> String {
        self.translations
            .get(key.as_ref())
            .cloned()
            .unwrap_or_else(|| format!("!{}!", key.as_ref()))
    }

    pub fn get_fmt(&self, key: impl AsRef<str>, vars: &HashMap<&str, &str>) -> String {
        let mut s = self.get(key);
        for (k, v) in vars {
            let needle = format!("{{{}}}", k);
            if s.contains(&needle) {
                s = s.replace(&needle, v);
            }
        }
        s
    }

    #[inline]
    pub fn contains(&self, key: impl AsRef<str>) -> bool {
        self.translations.contains_key(key.as_ref())
    }

    #[inline]
    pub fn language(&self) -> Language {
        self.language.clone()
    }

    #[inline]
    pub fn size(&self) -> usize {
        self.size
    }

    pub fn keys(&self) -> Vec<&str> {
        self.translations.keys().map(|k| k.as_str()).collect()
    }
}

#[derive(Debug)]
pub struct I18nManager {
    base_dir: PathBuf,
    catalog: LocalizationCatalog,
}

impl I18nManager {
    pub fn init(base_dir: impl Into<PathBuf>) -> Result<Self, I18nError> {
        let base_dir = base_dir.into();
        let lang = Language::detect();
        let catalog = LocalizationCatalog::load(lang, &base_dir)
            .or_else(|_| LocalizationCatalog::load(Language::En, &base_dir))?;
        Ok(Self { base_dir, catalog })
    }

    pub fn reload(&mut self) -> Result<(), I18nError> {
        self.catalog = LocalizationCatalog::load(self.catalog.language(), &self.base_dir)?;
        Ok(())
    }

    pub fn set_language(&mut self, lang: Language) -> Result<(), I18nError> {
        self.catalog = LocalizationCatalog::load(lang, &self.base_dir)?;
        Ok(())
    }

    #[inline]
    pub fn t(&self, key: impl AsRef<str>) -> String {
        self.catalog.get(key)
    }

    #[inline]
    pub fn t_fmt(&self, key: impl AsRef<str>, vars: &HashMap<&str, &str>) -> String {
        self.catalog.get_fmt(key, vars)
    }

    #[inline]
    pub fn language(&self) -> Language {
        self.catalog.language()
    }

    #[inline]
    pub fn keys(&self) -> Vec<&str> {
        self.catalog.keys()
    }

    #[inline]
    pub fn size(&self) -> usize {
        self.catalog.size()
    }
}

fn flatten_json(value: &Value) -> Result<HashMap<String, String>, I18nError> {
    let mut map = HashMap::new();
    flatten_json_inner("", value, &mut map);
    Ok(map)
}

fn flatten_json_inner(prefix: &str, value: &Value, out: &mut HashMap<String, String>) {
    match value {
        Value::Object(obj) => {
            for (k, v) in obj {
                let next = if prefix.is_empty() { k.clone() } else { format!("{}.{}", prefix, k) };
                flatten_json_inner(&next, v, out);
            }
        }
        Value::String(s) => {
            out.insert(prefix.to_string(), s.clone());
        }
        _ => {}
    }
}
