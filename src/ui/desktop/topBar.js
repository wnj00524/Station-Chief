export function renderTopBar({ clockEl, pcEl, state }) {
  clockEl.textContent = state.displayTime;
  pcEl.textContent = `Political Capital: ${state.politicalCapital}`;
}
