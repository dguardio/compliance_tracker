import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["menu"]

    connect() {
        this.close = this.close.bind(this)
    }

    toggle() {
        this.menuTarget.classList.toggle("hidden")

        if (!this.menuTarget.classList.contains("hidden")) {
            // Close when clicking outside
            document.addEventListener("click", this.close)
        } else {
            document.removeEventListener("click", this.close)
        }
    }

    close(event) {
        // Don't close if clicking inside the controller element
        if (this.element.contains(event.target)) {
            return
        }

        this.menuTarget.classList.add("hidden")
        document.removeEventListener("click", this.close)
    }

    disconnect() {
        document.removeEventListener("click", this.close)
    }
}
