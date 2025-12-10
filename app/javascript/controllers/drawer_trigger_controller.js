import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = { id: String }

    connect() { }

    open(event) {
        event.preventDefault()

        window.dispatchEvent(new CustomEvent('drawer:open', {
            detail: { id: this.idValue }
        }))
    }
}
