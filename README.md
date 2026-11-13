# 🧊 FridgeChef

Flutter-App für **iOS und Android**: Kühlschrank fotografieren, die KI (Claude) erkennt die Lebensmittel, und die App schlägt Rezepte vor, die **möglichst viele vorhandene Zutaten nutzen** – mit Fokus auf Resteverwertung.

## Funktionen

| Bereich | Was die App kann |
|---|---|
| **Scan** | Ein oder mehrere Fotos (bis 6) per Kamera oder Galerie. Claude erkennt die Lebensmittel, fasst Doppelte über mehrere Fotos zusammen und schätzt Menge, Kategorie und Haltbarkeit. |
| **Zutatenliste** | Erkannte Lebensmittel prüfen, bearbeiten, abwählen, ergänzen. Unsichere Treffer sind markiert und vorab abgewählt. |
| **Vorrat** | Manuell pflegen, Ablaufdatum setzen (Schnellwahl +1/+3/+7/+14 Tage oder Kalender), bald ablaufende stehen oben und sind farbig markiert. |
| **Rezepte** | Vorschläge von Claude, lokal sortiert nach *Anzahl vorhandener Zutaten* → *wenigste fehlende* → *kürzeste Zeit*. Fortschrittsbalken „3 von 5 Zutaten vorhanden“. „Weitere Rezepte“ lädt neue, ohne Wiederholungen. |
| **Resteverwertung** | Bald ablaufende Lebensmittel werden im Prompt hervorgehoben und zählen beim Ranking doppelt. Abschaltbar. |
| **Filter** | Vegetarisch, vegan, glutenfrei, Low Carb, max. Kochzeit, max. Schwierigkeit. Werden an die KI übergeben **und** lokal erzwungen. |
| **Rezeptansicht** | Portionsrechner (Mengen skalieren live, mit Brüchen wie ½), vorhanden/fehlt pro Zutat, Nährwerte pro Portion oder gesamt – klar als **Schätzung** gekennzeichnet. |
| **Kochmodus** | Schritt für Schritt im Großformat, Bildschirm bleibt an, Timer pro Schritt (aus dem Rezept) plus eigene Timer, laufende Timer immer sichtbar, Vibration + Ton bei Ablauf. Am Ende optional verbrauchte Zutaten aus dem Vorrat entfernen. |
| **Einkaufsliste** | Fehlende Zutaten mit einem Tipp hinzufügen (einzeln oder alle). Gleiche Artikel werden zusammengeführt. Abgehakte Artikel in den Vorrat übernehmen. |
| **Wochenplaner** | Frühstück/Mittag/Abend für jede Woche, Rezepte aus Favoriten/Vorschlägen/Verlauf. Fehlende Zutaten der ganzen Woche auf die Einkaufsliste. |
| **Favoriten & Verlauf** | Herz im Rezept; Verlauf der zuletzt angesehenen Rezepte (max. 50). |
| **Wunsch-Eingabe** | Freitext wie „etwas Asiatisches“ fließt in die Rezeptvorschläge ein. |
| **Allergien & Abneigungen** | Zutaten, die nie vorkommen sollen: gehen an die KI und werden zusätzlich lokal herausgefiltert. |
| **Ersatz finden** | Fehlende Zutat antippen: Claude schlägt Alternativen vor, bevorzugt aus dem Vorrat. |
| **Vorrat-Suche & Gruppierung** | Suchfeld ab 7 Einträgen, optional nach Kategorie gruppiert. |
| **Kopieren/Teilen** | Rezept (mit skalierten Mengen) und Einkaufsliste als Text in die Zwischenablage. |
| **Bilanz** | Zählt gekochte Gerichte und gerettete (bald ablaufende) Lebensmittel. |
| **Kalorienzähler** | Tagebuch mit Tagesziel, Makros und 7-Tage-Übersicht. Einträge aus einem Rezept („Als gegessen eintragen“), von Hand oder per KI-Schätzung aus Beschreibung/Foto. |
| **Kassenbon-Scan** | Bon fotografieren: die gekauften Lebensmittel landen (nach Prüfung) im Vorrat. |
| **Mengen mitrechnen** | Nach dem Kochen zieht die App verbrauchte Mengen ab (g/kg, ml/l, Stück); Unklares entscheidest du. |
| **Eigene Rezepte** | Rezept eintippen, einfügen oder aus dem Kochbuch fotografieren – Claude überträgt es ins App-Format. |
| **Bewertungen** | 1–5 Sterne pro Rezept; gut und schlecht Bewertetes fließt in künftige Vorschläge ein. |
| **Kalorienziel-Rechner** | Persönlicher Richtwert nach Mifflin-St-Jeor (Angaben werden nicht gespeichert). |
| **Plan ↔ Kalorien** | Geplante Gerichte erscheinen im Kalorienzähler und lassen sich mit einem Tipp als gegessen eintragen; der Wochenplan zeigt die geplanten kcal pro Tag. |
| **Häufige Mahlzeiten** | Oft Gegessenes mit einem Tipp erneut eintragen. |
| **Pro-Version** | Kostenlos: 5 KI-Anfragen pro Tag. Pro: unbegrenzt, dazu Kassenbon-Scan, Rezept-Import, Ersatz-Vorschläge, KI-Kalorienschätzung und automatischer Wochenplan. Der Kauf ist noch nicht angebunden: `ProStore.setPro` wird derzeit per Schalter gesetzt und muss später aus dem Store-Kauf aufgerufen werden. |
| **Automatischer Wochenplan** | (Pro) Füllt freie Abendessen der Woche mit Rezepten aus dem Vorrat, bald Ablaufendes zuerst. |
| **Heute-Übersicht, Onboarding, Wasser-Zähler** | Übersicht im Vorrat, Einführung beim ersten Start, Gläser Wasser pro Tag im Kalorienzähler. |
| **Darstellung** | Hell, Dunkel oder System (Material 3). Deutsch und Englisch (oder Systemsprache) – auch die KI antwortet in der gewählten Sprache. |

Alle Daten bleiben lokal auf dem Gerät (SharedPreferences). Der API-Schlüssel liegt verschlüsselt im Keychain/Keystore.

## Einrichtung

Voraussetzungen: Flutter ≥ 3.35 (getestet mit 3.47), Xcode bzw. Android Studio, ein [Claude-API-Schlüssel](https://platform.claude.com/).

```bash
flutter pub get
flutter run
```

Den API-Schlüssel dann in der App unter **Mehr → Einstellungen → KI-Zugang** eintragen.

Alternativ für die Entwicklung beim Build mitgeben:

```bash
flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

Weitere Build-Optionen (`--dart-define`):

| Variable | Standard | Zweck |
|---|---|---|
| `ANTHROPIC_API_KEY` | – | Eingebauter Schlüssel (nur Entwicklung) |
| `ANTHROPIC_BASE_URL` | `https://api.anthropic.com` | Eigener Backend-Proxy |
| `CLAUDE_MODEL` | `claude-opus-5-5` | Verwendetes Modell |

### Web-Vorschau (z. B. am iPhone)

Die Web-Version läuft auch als claude.ai-Artifact. Dort fragt die App Claude über das claude.ai-Konto der Person, die sie öffnet (kein API-Schlüssel nötig):

```bash
flutter build web --release --no-web-resources-cdn --no-source-maps
python3 tool/web_artifact.py build/web /tmp/fridgechef-artifact
```

### ⚠️ Vor einer Veröffentlichung

* **Keinen API-Schlüssel in die App einbauen.** Alles, was in einer App-Binary steckt, lässt sich auslesen. Für den Store einen kleinen Backend-Proxy betreiben, der den Schlüssel serverseitig hinzufügt (und Nutzer authentifiziert/limitiert), und `ANTHROPIC_BASE_URL` darauf zeigen lassen.
* **Kosten:** Standardmäßig wird Claude Opus 5.5 verwendet ($4 / $20 pro Mio. Eingabe-/Ausgabe-Tokens). Eine Runde mit 6 Rezeptvorschlägen erzeugt einige tausend Ausgabe-Tokens – grob 10–30 Cent; ein Scan ist meist günstiger. Mit `CLAUDE_MODEL` lässt sich ein günstigeres Modell wählen (vorher testen).
* **Datenschutz:** Fotos und Vorratsliste werden zur Analyse an Anthropic gesendet – das gehört in die Datenschutzerklärung.
* Die Bundle-ID ist `com.fridgechef.fridgechef` – vor dem Release auf eure eigene ändern (`android/app/build.gradle.kts`, Xcode-Projekt).

## Architektur

```
lib/
├── main.dart / app.dart        # Start, Provider, Theme (hell/dunkel), Lokalisierung
├── config.dart                 # --dart-define-Konfiguration
├── l10n/                       # Strings (abstrakte Klasse S + Deutsch/Englisch)
├── models/                     # PantryItem, Recipe, RecipeFilters, ShoppingItem, MealPlanEntry
├── logic/
│   ├── recipe_ranking.dart     # Abgleich Rezept ↔ Vorrat, Sortierung, Resteverwertung
│   └── scaling.dart            # Portionsrechner, Mengen-/Zeitformatierung
├── services/
│   ├── claude_client.dart      # Schlanker Client für die Messages API (HTTP)
│   ├── fridge_ai_service.dart  # Prompts + JSON-Schemas für Erkennung & Rezepte
│   ├── image_utils.dart        # Bildformat-Erkennung
│   └── storage.dart            # Lokale Speicherung, sicherer Schlüssel-Speicher
├── state/                      # ChangeNotifier-Stores (provider)
└── ui/                         # Screens: pantry, scan, recipes, cooking, planner, shopping, more
```

**KI-Anbindung:** Es gibt kein offizielles Anthropic-SDK für Dart, daher spricht `ClaudeClient` die Messages API (`POST /v1/messages`) direkt an. Beide Aufgaben nutzen **Structured Outputs** (`output_config.format` mit JSON-Schema), damit die Antworten immer parsebar sind. Bei Überlastung/Rate-Limit wird automatisch erneut versucht; Ablehnungen und abgeschnittene Antworten werden erkannt und verständlich angezeigt. Zusätzlich ist der serverseitige Fallback (`fallbacks: "default"`) aktiv.

**Ranking:** Claude ordnet jeder Rezeptzutat den passenden Vorratseintrag zu (`pantryItem`). Die App prüft das lokal gegen den echten Vorrat (inkl. Teilwort-Abgleich wie „Cherrytomaten“ ↔ „Tomaten“) und sortiert selbst – so ändert sich die Reihenfolge sofort, wenn sich der Vorrat ändert. Grundzutaten (Salz, Öl …) zählen nie als fehlend.

## Tests

```bash
flutter analyze
flutter test
```

Abgedeckt: Ranking, Portionsrechner, Filter, Timer, API-Client (Header, Body, Fehler, Retry, Refusal), Prompt-Aufbau, Schema-Regeln sowie ein Widget-Test des kompletten Ablaufs Vorrat → Rezepte → Filter → Portionen → Einkaufsliste → Kochmodus → Verlauf und der Sprach-/Theme-Umschaltung (mit gemockter API).

## Bekannte Grenzen

* Timer laufen nur, solange die App im Vordergrund ist (keine Hintergrund-Benachrichtigungen – dafür wäre z. B. `flutter_local_notifications` nötig).
* Keine Synchronisation zwischen Geräten; alles ist lokal.
* Bereits geladene Rezepte bleiben nach einem Sprachwechsel in der alten Sprache, bis neue vorgeschlagen werden.

## Lizenz

MIT – siehe [LICENSE](LICENSE).
