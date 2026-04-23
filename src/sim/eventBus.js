export class EventBus {
  constructor() {
    this.listeners = new Map();
  }

  on(eventName, callback) {
    const list = this.listeners.get(eventName) || [];
    list.push(callback);
    this.listeners.set(eventName, list);
    return () => this.listeners.set(eventName, (this.listeners.get(eventName) || []).filter((cb) => cb !== callback));
  }

  emit(eventName, payload) {
    (this.listeners.get(eventName) || []).forEach((cb) => cb(payload));
  }
}
