/// Klartext zu den genormten OBD2-Fehlercodes (ISO 15031-6 / SAE J2012).
///
/// Bewusst nur die generischen P0xxx/U0xxx-Codes: die sind öffentlich
/// dokumentiert und für alle Hersteller identisch. Herstellerspezifische
/// Codes (P1xxx, P3xxx) stehen nicht drin – dafür gibt es keine freie Quelle.
const dtcDescriptions = <String, String>{
  // Gemischbildung
  'P0170': 'Gemischbildung fehlerhaft (Bank 1)',
  'P0171': 'Gemisch zu mager (Bank 1)',
  'P0172': 'Gemisch zu fett (Bank 1)',
  'P0173': 'Gemischbildung fehlerhaft (Bank 2)',
  'P0174': 'Gemisch zu mager (Bank 2)',
  'P0175': 'Gemisch zu fett (Bank 2)',

  // Luftmasse / Ansaugung
  'P0100': 'Luftmassenmesser – Signalfehler',
  'P0101': 'Luftmassenmesser – Signal unplausibel',
  'P0102': 'Luftmassenmesser – Signal zu niedrig',
  'P0103': 'Luftmassenmesser – Signal zu hoch',
  'P0105': 'Saugrohrdrucksensor – Signalfehler',
  'P0107': 'Saugrohrdrucksensor – Signal zu niedrig',
  'P0108': 'Saugrohrdrucksensor – Signal zu hoch',
  'P0110': 'Ansauglufttemperatursensor – Signalfehler',
  'P0112': 'Ansauglufttemperatursensor – Signal zu niedrig',
  'P0113': 'Ansauglufttemperatursensor – Signal zu hoch',

  // Kühlmittel / Temperatur
  'P0115': 'Kühlmitteltemperatursensor – Signalfehler',
  'P0116': 'Kühlmitteltemperatursensor – Signal unplausibel',
  'P0117': 'Kühlmitteltemperatursensor – Signal zu niedrig',
  'P0118': 'Kühlmitteltemperatursensor – Signal zu hoch',
  'P0128': 'Thermostat – Betriebstemperatur nicht erreicht',

  // Drosselklappe / Pedal
  'P0120': 'Drosselklappenpotentiometer – Signalfehler',
  'P0121': 'Drosselklappenpotentiometer – Signal unplausibel',
  'P0122': 'Drosselklappenpotentiometer – Signal zu niedrig',
  'P0123': 'Drosselklappenpotentiometer – Signal zu hoch',
  'P0130': 'Lambdasonde 1 (Bank 1) – Signalfehler',
  'P0133': 'Lambdasonde 1 (Bank 1) – Reaktion zu langsam',
  'P0135': 'Lambdasondenheizung 1 (Bank 1) – Fehler',
  'P0136': 'Lambdasonde 2 (Bank 1) – Signalfehler',
  'P0137': 'Lambdasonde 2 (Bank 1) – Spannung zu niedrig',
  'P0138': 'Lambdasonde 2 (Bank 1) – Spannung zu hoch',
  'P0141': 'Lambdasondenheizung 2 (Bank 1) – Fehler',

  // Katalysator / Abgas
  'P0420': 'Katalysator – Wirkungsgrad unter Grenzwert (Bank 1)',
  'P0421': 'Vorkatalysator – Wirkungsgrad zu gering (Bank 1)',
  'P0430': 'Katalysator – Wirkungsgrad unter Grenzwert (Bank 2)',
  'P0401': 'Abgasrückführung – Durchsatz zu gering',
  'P0402': 'Abgasrückführung – Durchsatz zu hoch',
  'P0403': 'Abgasrückführventil – Stromkreis fehlerhaft',
  'P0411': 'Sekundärluftsystem – Durchsatz fehlerhaft',
  'P2002': 'Dieselpartikelfilter – Wirkungsgrad zu gering (Bank 1)',
  'P2463': 'Dieselpartikelfilter – Rußbeladung zu hoch',

  // Zündung / Verbrennungsaussetzer
  'P0300': 'Verbrennungsaussetzer – mehrere Zylinder',
  'P0301': 'Verbrennungsaussetzer – Zylinder 1',
  'P0302': 'Verbrennungsaussetzer – Zylinder 2',
  'P0303': 'Verbrennungsaussetzer – Zylinder 3',
  'P0304': 'Verbrennungsaussetzer – Zylinder 4',
  'P0305': 'Verbrennungsaussetzer – Zylinder 5',
  'P0306': 'Verbrennungsaussetzer – Zylinder 6',
  'P0351': 'Zündspule A – Primär-/Sekundärkreis',
  'P0352': 'Zündspule B – Primär-/Sekundärkreis',

  // Kraftstoffsystem
  'P0087': 'Kraftstoffdruck zu niedrig',
  'P0088': 'Kraftstoffdruck zu hoch',
  'P0089': 'Kraftstoffdruckregler – Funktion fehlerhaft',
  'P0190': 'Kraftstoffdrucksensor – Signalfehler',
  'P0201': 'Einspritzventil Zylinder 1 – Stromkreis',
  'P0202': 'Einspritzventil Zylinder 2 – Stromkreis',
  'P0203': 'Einspritzventil Zylinder 3 – Stromkreis',
  'P0204': 'Einspritzventil Zylinder 4 – Stromkreis',
  'P0442': 'Tankentlüftung – kleines Leck',
  'P0455': 'Tankentlüftung – großes Leck',

  // Aufladung
  'P0234': 'Ladedruck zu hoch',
  'P0299': 'Ladedruck zu niedrig',
  'P0045': 'Ladedrucksteller – Stromkreis',

  // Kurbelwelle / Nockenwelle
  'P0335': 'Kurbelwellensensor – Signalfehler',
  'P0336': 'Kurbelwellensensor – Signal unplausibel',
  'P0340': 'Nockenwellensensor – Signalfehler',
  'P0341': 'Nockenwellensensor – Signal unplausibel',
  'P0011': 'Nockenwellenverstellung Bank 1 – Position fehlerhaft',
  'P0016': 'Kurbel-/Nockenwelle – Zuordnung fehlerhaft',

  // Getriebe
  'P0700': 'Getriebesteuerung – Fehler eingetragen',
  'P0715': 'Turbinendrehzahlsensor – Signalfehler',
  'P0730': 'Übersetzungsverhältnis fehlerhaft',
  'P0741': 'Wandlerkupplung – mechanisch hängend',

  // Bordnetz / Kommunikation
  'P0562': 'Bordspannung zu niedrig',
  'P0563': 'Bordspannung zu hoch',
  'P0600': 'CAN-Bus – Kommunikationsfehler',
  'P0601': 'Steuergerät – Speicherfehler (Prüfsumme)',
  'P0620': 'Generatorregelung – Stromkreis',
  'U0073': 'CAN-Bus – Kommunikation deaktiviert',
  'U0100': 'Keine Kommunikation mit Motorsteuergerät',
  'U0101': 'Keine Kommunikation mit Getriebesteuergerät',
  'U0121': 'Keine Kommunikation mit ABS-Steuergerät',
  'U0140': 'Keine Kommunikation mit Bordnetzsteuergerät',
  'U0155': 'Keine Kommunikation mit Kombiinstrument',
};
