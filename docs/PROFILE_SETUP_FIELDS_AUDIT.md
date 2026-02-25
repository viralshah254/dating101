# Profile setup wizard – fields audit

This doc maps the **reference app** (screenshots: About, Photos, Career, Education, Family, Horoscope, Looking For) to our **saathi profile setup** so we collect the same info with better UI/UX.

---

## 1. Reference app → our steps

| Reference tab | Reference fields | Our step | Our fields | Status |
|---------------|------------------|----------|------------|--------|
| **About** | Bio, Height, Location, Marital status, Religion/Community, Languages, Income, Health (Thalassemia, HIV+), Diet, Drink, Smoke | Identity + Details | Name, DOB, Location, Hometown, Height, Body type, Marital status, Disability; Religion, Community, Mother tongue, Languages; Income; Lifestyle (diet, drink, smoke, exercise); Bio; Interests | ✅ Covered. Optional: explicit health (Thalassemia/HIV) vs generic disability. |
| **Photos** | Multiple photos (e.g. 6), primary | Step 2 Photos | 6-slot grid, primary | ✅ Match |
| **Career** | Job title, Company + location + sector, Earnings, "About her career" (free text) | Details – Career card | Occupation, Company, Income, Work location, Settled abroad, Willing to relocate | ⚠️ **Missing:** Sector (Private/Govt/PSU/Business), "About career" free text |
| **Education** | Multiple qualifications (degree + institution), "About her education" (free text) | Details – Career card | Single education dropdown | ⚠️ **Missing:** "About education" free text; optional multiple qualifications |
| **Family** | Based out of (location), Household income, Family type, Mother occupation, Father occupation, Siblings | Details – Family card | Family type, Family values | ⚠️ **Missing:** Family location, Household income, Mother occupation, Father occupation, Siblings |
| **Horoscope** | Rashi, Nakshatra, Manglik, Birth date + time + place, Zodiac | Details – Horoscope card | Manglik, Rashi, Nakshatra, Gotra | ⚠️ **Missing:** Birth time, Birth place (for horoscope); DOB we have in Identity |
| **Looking For** | Religion, Country, Education, Earning, Diet, Smoke, Drink, Age | Step 4 Preferences | Age, Religion, Mother tongue, Education, Marital status, Income, Diet, Drink, Smoke, Settled abroad, City | ⚠️ **Missing:** Country preference (we have city) |

---

## 2. Field list by our wizard step

### Step 1 – Identity
- Creating for (self / son / daughter / brother / sister / friend / relative)
- Name (2+ words, title case) *
- Gender *
- Interested in / Looking for (Bride/Groom)
- Date of birth *
- Location (where they live)
- Hometown (matrimony)
- **Physical:** Height, Body type, Complexion (matrimony), Marital status, Disability (matrimony)

### Step 2 – Photos
- 6 photo slots, primary = first

### Step 3 – Details (matrimony)
- **Background:** Religion, Community, Mother tongue, Languages spoken
- **Career:** Education, Occupation, Company, Income, Work location, Settled abroad, Willing to relocate  
  → **To add:** Sector, About career (free text), About education (free text)
- **Lifestyle:** Diet, Drink, Smoke, Exercise
- **Family:** Family type, Family values  
  → **To add:** Family location (based out of), Household income, Mother occupation, Father occupation, Siblings
- **Horoscope:** Manglik, Rashi, Nakshatra, Gotra  
  → **To add:** Birth time, Birth place (city)
- **About:** Bio (free text)
- **Interests:** Multi-select with search

### Step 4 – Preferences (matrimony)
- Age range, Religion, Mother tongue, Education, Marital status, Income, Diet, Drink, Smoke, Settled abroad, City  
  → **To add:** Country preference

---

## 3. UI/UX improvements (vs reference)

- **No blocking overlays** (e.g. avoid “Screenshot detected” covering content).
- **Clear section hierarchy:** one card per section (Background, Career, Family, Horoscope, About, Interests), optional badges, consistent spacing.
- **Optional narrative fields:** “About career”, “About education” as short multiline text for richer profiles.
- **Family section:** same card style, add household income, family location, mother/father occupation, siblings so it matches what we’ll show on the match profile.
- **Horoscope:** add birth time + birth place in the same card so we can display “Born in X at Y” on the profile.
- **Preferences:** add country (multi or single) so “Looking for” matches reference.
- **Mandatory vs optional:** only Identity step is mandatory; rest skippable with “Skip for now”, so we stay flexible but collect as much as users want.

---

## 4. Next: match profile screen

After profile setup is aligned and polished, we’ll design the **match/user profile view** (how we display About, Photos, Career, Education, Family, Horoscope, Looking For) with a cleaner layout than the reference and no intrusive overlays.
