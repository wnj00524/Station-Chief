export default {
  "id": "falcon_meeting",
  "title": "The Falcon Meeting",
  "startTime": "08:00",
  "decisionDeadlineMinutes": 10,
  "startingPoliticalCapital": 50,
  "locations": [
    { "id": "cafe_sirocco", "name": "Cafe Sirocco", "coords": [42.11, 18.55] },
    { "id": "airport_perimeter", "name": "Mazar Airport Perimeter", "coords": [42.20, 18.63] },
    { "id": "river_checkpoint", "name": "River Checkpoint", "coords": [42.15, 18.61] }
  ],
  "npcs": [
    { "id": "nabil_rahman", "name": "Nabil Rahman", "role": "Informant (Codename: Falcon)", "knownLocation": "cafe_sirocco" },
    { "id": "sara_ilyas", "name": "Sara Ilyas", "role": "Signals Analyst", "knownLocation": "hq" },
    { "id": "maj_haleem", "name": "Major Haleem", "role": "Field Team Lead", "knownLocation": "river_checkpoint" }
  ],
  "groundTruth": {
    "informantCompromised": true,
    "handoffLocation": "airport_perimeter",
    "phoneLocation": "airport_perimeter"
  },
  "inboxThreads": [
    {
      "id": "thread_falcon",
      "subject": "Falcon: ready for meet",
      "messages": [
        {
          "atMinute": 0,
          "from": "Nabil Rahman",
          "body": "I'm at Cafe Sirocco now. Contact arriving in under 20 minutes. Need immediate direction.",
          "type": "humint"
        }
      ]
    }
  ],
  "intercepts": [
    {
      "id": "int_001",
      "availableAtMinute": 1,
      "title": "IMSI ping // Falcon handset",
      "summary": "Handset geolocates near Mazar Airport perimeter road.",
      "locationId": "airport_perimeter"
    },
    {
      "id": "int_002",
      "availableAtMinute": 3,
      "title": "Tower handoff metadata",
      "summary": "Device moved between airport towers A2 and A3; no hits near Cafe Sirocco.",
      "locationId": "airport_perimeter"
    }
  ],
  "staffTemplates": [
    {
      "id": "analyst_verify",
      "label": "Task Sara Ilyas: Verify source location",
      "durationMinutes": 2,
      "resultMessage": {
        "subject": "Verification Report: Falcon",
        "from": "Sara Ilyas",
        "body": "Cross-check complete. 93% confidence Falcon is not at Cafe Sirocco. Metadata and local camera feed suggest airport perimeter staging.",
        "type": "analysis"
      }
    },
    {
      "id": "surveil_airport",
      "label": "Task Major Haleem: Deploy surveillance near airport",
      "durationMinutes": 3,
      "resultMessage": {
        "subject": "Field Update: Airport",
        "from": "Major Haleem",
        "body": "Unmarked van and two armed escorts spotted at airport perimeter. Possible handoff window now.",
        "type": "field"
      }
    }
  ],
  "decisions": [
    {
      "id": "trust_cafe",
      "label": "Trust HUMINT: send team to Cafe Sirocco",
      "outcome": "failure",
      "politicalCapitalDelta": -12,
      "debrief": "Home Office: Team arrived at cafe too late and empty-handed. Rival service executed handoff at airport. Confidence in station judgment reduced."
    },
    {
      "id": "verify_then_airport",
      "label": "Verify then redirect to airport",
      "outcome": "success",
      "politicalCapitalDelta": 10,
      "debrief": "Home Office: Strong analytical discipline. Handoff intercepted near airport perimeter; material secured with minimal exposure."
    },
    {
      "id": "surveil_airport_now",
      "label": "Immediate airport surveillance",
      "outcome": "partial_success",
      "politicalCapitalDelta": 3,
      "debrief": "Home Office: You disrupted hostile movement near airport, but primary courier escaped. Partial operational gain acknowledged."
    },
    {
      "id": "abort",
      "label": "Abort / delay operation",
      "outcome": "partial_success",
      "politicalCapitalDelta": -2,
      "debrief": "Home Office: Conservative call prevented losses, but key opportunity likely missed."
    }
  ]
}
