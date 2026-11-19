import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 250 } }

  connect() {
    this.timeout = null
  }

  // Immediate submit for checkboxes, radios, sort dropdown
  submit() {
    this.element.requestSubmit()
  }

  // Debounced submit for text search & numeric price inputs
  debouncedSubmit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}