export class Scheduler {
  constructor() {
    this.queue = [];
  }

  schedule(event) {
    this.queue.push(event);
    this.queue.sort((a, b) => a.atMinute - b.atMinute);
  }

  scheduleMany(events) {
    events.forEach((event) => this.schedule(event));
  }

  popDue(currentMinute) {
    const due = [];
    while (this.queue.length && this.queue[0].atMinute <= currentMinute) {
      due.push(this.queue.shift());
    }
    return due;
  }
}
