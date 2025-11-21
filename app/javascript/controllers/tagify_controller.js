import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.tagify = new window.Tagify(this.element)
  }

  disconnect() {
    this.tagify.destroy()
  }
}
