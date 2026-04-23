/**
 * @typedef {Object} CaseDefinition
 * @property {string} id
 * @property {string} title
 * @property {string} startTime
 * @property {number} decisionDeadlineMinutes
 * @property {number} startingPoliticalCapital
 * @property {Array<{id: string, name: string, coords: [number, number]}>} locations
 * @property {Array<{id: string, name: string, role: string, knownLocation: string}>} npcs
 * @property {Object} groundTruth
 * @property {Array<{id: string, subject: string, messages: Array<{atMinute: number, from: string, body: string, type: string}>}>} inboxThreads
 * @property {Array<{id: string, availableAtMinute: number, title: string, summary: string, locationId: string}>} intercepts
 * @property {Array<{id: string, label: string, durationMinutes: number, resultMessage: {subject: string, from: string, body: string, type: string}}>} staffTemplates
 * @property {Array<{id: string, label: string, outcome: string, politicalCapitalDelta: number, debrief: string}>} decisions
 */

const REQUIRED_ROOT_FIELDS = [
  'id',
  'title',
  'startTime',
  'decisionDeadlineMinutes',
  'startingPoliticalCapital',
  'locations',
  'npcs',
  'groundTruth',
  'inboxThreads',
  'intercepts',
  'staffTemplates',
  'decisions'
];

/**
 * Lightweight schema validation for vertical-slice authored case data.
 * Returns an error list without mutating content.
 *
 * @param {CaseDefinition} caseData
 * @returns {string[]}
 */
export function validateCaseDefinition(caseData) {
  const errors = [];

  REQUIRED_ROOT_FIELDS.forEach((field) => {
    if (!(field in caseData)) errors.push(`Missing required field: ${field}`);
  });

  if (!Array.isArray(caseData.locations) || caseData.locations.length === 0) {
    errors.push('Case must define at least one location.');
  }

  if (!Array.isArray(caseData.decisions) || caseData.decisions.length < 3) {
    errors.push('Case must define at least three decision options.');
  }

  const locationIds = new Set((caseData.locations || []).map((location) => location.id));
  (caseData.intercepts || []).forEach((intercept) => {
    if (!locationIds.has(intercept.locationId)) {
      errors.push(`Intercept ${intercept.id} references unknown location: ${intercept.locationId}`);
    }
  });

  return errors;
}
