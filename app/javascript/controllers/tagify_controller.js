
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { whitelist: Array }

  connect() {
    // Configure Tagify to act as a searchable dropdown
    // Whitelist is passed via Stimulus Values (data-tagify-whitelist-value)
    let whitelist = this.whitelistValue || []

    // Ensure whitelist is a flat array of strings
    whitelist = whitelist.flat()

    const settings = {
      whitelist: whitelist,
      enforceWhitelist: false,
      originalInputValueFormat: valuesArr => valuesArr.map(item => item.value).join(','),
      dropdown: {
        enabled: 0,             // show suggestions on focus
        maxItems: 20,           // limit number of items
        closeOnSelect: false,   // keep open for multiple selection
        highlightFirst: true
      }
    }

    this.tagify = new window.Tagify(this.element, settings)
  }

  disconnect() {
    if (this.tagify) {
      this.tagify.destroy()
    }
  }

  addTags(tags) {
    if (this.tagify) {
      this.tagify.addTags(tags)
    }
  }
}
