export function renderInboxView(state) {
  const threads = state.inbox
    .map(
      (thread) => `
      <div class="panel">
        <strong>${thread.subject}</strong>
        ${thread.messages
          .map(
            (message) => `<div class="thread-msg"><div><b>${message.from}</b> @ ${String(message.atMinute).padStart(2, '0')}m</div><div>${message.body}</div></div>`
          )
          .join('')}
      </div>`
    )
    .join('');

  return `
    <h2>Inbox</h2>
    <p class="small">Read incoming HUMINT/SIGINT/staff reports. No hints are auto-generated.</p>
    ${threads}
  `;
}
