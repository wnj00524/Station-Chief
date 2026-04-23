**GAME DESIGN DOCUMENT: STATION_CHIEF**

**Version:** 1.1

**Project Type:** Hardcore Intelligence Simulation

**Technical Stack:** C# / .NET / Unity or Godot (Logic-Driven)

**Aesthetic:** Diegetic Ubuntu-Inspired OS

**1\. PROJECT OVERVIEW**

**1.1 Executive Summary**

**STATION_CHIEF** is a "desk exercise" thriller. The player acts as a foreign intelligence officer stationed in a contested regional office. The game is played entirely through a virtual computer interface. The player does not "see" the world; they interpret it through data, human intelligence (HUMINT), and signals intelligence (SIGINT).

**1.2 The "North Star" Pillars**

- **Pure Simulation:** No "Quest Markers." Discrepancies in data must be found by the player's own eyes.
- **Diegetic Interface:** If it isn't on the desktop, it doesn't exist. The UI _is_ the world.
- **Real-Time Pressure:** The clock never stops. While you read an old transcript, a live operation might be failing.
- **Stability Agnosticism:** Rival agencies aren't "evil"; they are pragmatic actors with conflicting interests.

**2\. THE INTERFACE (VIRTUAL OS)**

**2.1 The "Ubuntu" Shell**

The UI mimics a modern Linux distribution (Ubuntu/GNOME).

- **The Launcher (Dock):** Left-side vertical bar. Contains "Apps": _Inbox, GIS Map, Database Search, Terminal, System Monitor, Media Player._
- **Top Bar:** System clock (Global/Local), Connection Strength (determines DB search speed), and **Political Capital (PC)** counter.
- **Workspaces:** Ability to switch between "Desktop 1" (Intel Analysis) and "Desktop 2" (Personal/Music/Non-work files).

**2.2 Core Applications**

- **The Inbox:**
  - Supports threaded conversations.
  - Multi-option response system: Choose tone (Formal, Urgent, Cryptic) and content.
  - Tasking: Send orders to field assets via encrypted mail.
- **The Map (GIS):**
  - Static topographical map of the remit region.
  - **Manual Tagging:** Players click coordinates to place pins. Pins can be linked to "Nominal" profiles.
- **Database Suite:**
  - **Nominals:** Records of individuals (biometrics, known associates).
  - **Registry:** Business ownership and financial trails.
  - **Intercepts:** Raw audio files (waveforms) and text transcripts.
- **The Terminal:**
  - Command-line access for advanced queries.
  - Example: query --db nominals --attr alias "The Falcon"

**3\. GAMEPLAY MECHANICS**

**3.1 The Intelligence Cycle**

The core loop follows a four-stage process:

- **Collection:** Raw data arrives in the Inbox or Databases.
- **Processing:** Player assigns a **Staff Member** to analyze/verify raw data.
- **Correlation:** Player manually compares "Ground Truth" (Metadata) against "Reported Truth" (Informant emails).
- **Dissemination/Action:** Player tasks an asset to intervene or reports findings to the Home Office.

**3.2 Staff & Competency**

The player manages a small team of analysts.

- **Attributes:** _Analysis (Speed), Verification (Accuracy), Field Ops (Safety)._
- **Confidence Scores:** When a staffer finishes a task, they provide a report.
  - _High Competency:_ "I am 95% sure this meeting is a trap."
  - _Low Competency:_ "Meeting confirmed." (Might be a lie they missed).

**3.3 Veracity & Lies**

The game engine maintains a "Ground Truth" hidden from the player.

- **Signals Intelligence (SIGINT):** Usually 100% accurate (e.g., a phone was at these coordinates).
- **Human Intelligence (HUMINT):** Subject to bias, fear, or rival agency subversion.
- **The Discrepancy:** If an informant says "I am at the cafe" but the metadata shows their phone is at the "Airport," the player must notice this without a UI prompt.

**4\. THE WORLD SIMULATION**

**4.1 Faction Matrix**

The world is populated by autonomous factions within a fictional region.

| **Faction**          | **Logic Type**     | **Objective**                              |
| -------------------- | ------------------ | ------------------------------------------ |
| **Host State**       | Sovereign          | Autonomy; tracking foreign spies (you).    |
| **HIA (Rival)**      | Stability Agnostic | Maximize their home nation's ROI/Leverage. |
| **NIA (Neutral)**    | Status Quo         | Economic stability; avoiding conflict.     |
| **Station (Player)** | Pro-Interests      | Regional alignment with your home nation.  |

**4.2 Influence & Radicalization**

Every NPC has a "Susceptibility" rating.

- **Events:** A bomb attack by Faction A increases the "Fear" variable in the local population.
- **Reactions:** High "Fear" makes NPCs more likely to accept protection from Faction B (Authoritarian), even if Faction B is hostile to the Player.

**5\. TECHNICAL SPECIFICATIONS (C#)**

**5.1 Data-Driven Architecture**

The game uses a **decoupled simulation engine**. The "World" runs in a background thread, while the "Desktop" acts as a viewer/controller.

C#

// The core of the 'Pure Sim' logic

public class WorldEntity {

public Guid ID;

public Vector2 CurrentLocation; // Ground Truth

public List&lt;Affinity&gt; FactionAffinities;

// Generates noise or signals based on activity

public void GenerateMetadata() {

if (IsUsingPhone) {

WorldSignalBus.Publish(new SignalPing(ID, CurrentLocation));

}

}

}

**5.2 Real-Time Event Bus**

The **Event Bus** handles all "Desktop Notifications."

- OnEmailReceived: Triggers a sound and a toast notification.
- OnInterceptCaptured: Adds a new entry to the Database app.
- OnShiftEnded: Triggers the EOD (End of Day) report calculation.

**6\. PROGRESSION & CAREER**

**6.1 The "Flight Sim" Model**

There is no "Game Over." Failure is represented by **Resource Attrition**.

- **High Political Capital:** You get the "Pro" version of tools, more staff, and faster servers.
- **Low Political Capital:** Your Home Office loses faith. They cut your budget. You are left with one rookie staffer and a slow, laggy connection to the databases.
- **The End State:** The player decides when their career is over by "Resigning" (Final Score based on regional influence) or by being "Recalled" (Total failure).

**6.2 Emergent Case Files**

Cases are not scripted levels. They are generated by the Faction AI.

- If the HIA decides to bribe a local official, the "Business Registry" will update with a shell company.
- The "Metadata" will show increased calls between the HIA and the Official.
- The player "discovers" the case by noticing these patterns in the "Noise."

**7\. AESTHETIC & AUDIO**

- **Visuals:** Flat UI, dark mode, terminal fonts (Ubuntu Mono). Window management feels like a real OS (dragging, snapping, minimizing).
- **Audio:** Ambient office sounds (muffled phones, hum of servers). A personal media player allows the player to load AI-generated "Lo-fi Intel" tracks.
- **Tactility:** Keyboard shortcuts for everything. Typing sudo feels heavy and significant.