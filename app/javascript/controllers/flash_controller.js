import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.hideTimeout = setTimeout(() => this.dismiss(), 3000);
  }

  disconnect() {
    clearTimeout(this.hideTimeout);
    clearTimeout(this.removeTimeout);
  }

  dismiss() {
    if (this.isDismissing) return;
    this.isDismissing = true;

    this.element.classList.add(
      "opacity-0",
      "translate-y-2",
      "pointer-events-none",
    );
    this.removeTimeout = setTimeout(() => this.element.remove(), 400);
  }
}
