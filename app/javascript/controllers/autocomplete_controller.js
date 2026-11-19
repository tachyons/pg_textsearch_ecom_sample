import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String }

  connect() {
    this.selectedIndex = -1
    this.boundGlobalKeydown = this.handleGlobalKeydown.bind(this)
    document.addEventListener("keydown", this.boundGlobalKeydown)
  }

  disconnect() {
    clearTimeout(this.timeout)
    document.removeEventListener("keydown", this.boundGlobalKeydown)
  }

  handleGlobalKeydown(event) {
    // Focus search on '/' or 'Cmd+K' / 'Ctrl+K' when not in another input
    if (
      (event.key === "/" || ((event.metaKey || event.ctrlKey) && event.key === "k")) &&
      !["INPUT", "TEXTAREA", "SELECT"].includes(document.activeElement.tagName)
    ) {
      event.preventDefault()
      this.inputTarget.focus()
      this.inputTarget.select()
    }
  }

  search() {
    clearTimeout(this.timeout)
    const q = this.inputTarget.value.trim()

    if (q.length < 2) {
      this.hideResults()
      return
    }

    this.timeout = setTimeout(() => {
      this.resultsTarget.src = `${this.urlValue}?q=${encodeURIComponent(q)}`
      this.resultsTarget.classList.remove("hidden")
      this.selectedIndex = -1
    }, 150)
  }

  onKeydown(event) {
    const results = this.getVisibleOptions()

    if (event.key === "ArrowDown") {
      event.preventDefault()
      if (results.length > 0) {
        this.selectedIndex = (this.selectedIndex + 1) % results.length
        this.updateSelection(results)
      }
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      if (results.length > 0) {
        this.selectedIndex = (this.selectedIndex - 1 + results.length) % results.length
        this.updateSelection(results)
      }
    } else if (event.key === "Enter") {
      if (this.selectedIndex >= 0 && results[this.selectedIndex]) {
        event.preventDefault()
        const link = results[this.selectedIndex].querySelector("a")
        if (link) {
          link.click()
          this.hideResults()
          return
        }
      }
      // Standard Enter submit: close suggestions and submit the form
      this.hideResults()
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.hideResults()
    }
  }

  getVisibleOptions() {
    return Array.from(this.resultsTarget.querySelectorAll("li[role='option']"))
  }

  updateSelection(options) {
    options.forEach((el, idx) => {
      if (idx === this.selectedIndex) {
        el.classList.add("bg-indigo-50/80")
        el.scrollIntoView({ block: "nearest" })
      } else {
        el.classList.remove("bg-indigo-50/80")
      }
    })
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  hideResults() {
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.classList.add("hidden")
    this.selectedIndex = -1
  }
}
