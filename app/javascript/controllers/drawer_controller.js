import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container", "panel", "backdrop"]

    connect() {
        this.element.setAttribute('aria-hidden', 'true')
        this.containerTarget.classList.add('hidden')

        // Listen for global open event
        this.boundOpen = this.open.bind(this)
        window.addEventListener('drawer:open', this.boundOpen)
    }

    disconnect() {
        if (this.boundOpen) {
            window.removeEventListener('drawer:open', this.boundOpen)
        }
    }

    // Open the drawer
    open(event) {
        // Check if this event is for this drawer
        if (event.detail && event.detail.id && event.detail.id !== this.element.id) {
            return
        }

        if (event) event.preventDefault()

        // Show container
        this.containerTarget.classList.remove('hidden')
        this.element.setAttribute('aria-hidden', 'false')

        // Animate in
        // Small timeout to allow display:block to apply before opacity transition
        setTimeout(() => {
            this.backdropTarget.classList.add('opacity-100')
            this.backdropTarget.classList.remove('opacity-0')

            this.panelTarget.classList.add('translate-x-0')
            this.panelTarget.classList.remove('translate-x-full')
        }, 10)

        // Prevent body scroll
        document.body.classList.add('overflow-hidden')
    }

    // Close the drawer
    close(event) {
        if (event) event.preventDefault()

        // Animate out
        this.backdropTarget.classList.remove('opacity-100')
        this.backdropTarget.classList.add('opacity-0')

        this.panelTarget.classList.remove('translate-x-0')
        this.panelTarget.classList.add('translate-x-full')

        // Hide container after animation
        setTimeout(() => {
            this.containerTarget.classList.add('hidden')
            this.element.setAttribute('aria-hidden', 'true')
            document.body.classList.remove('overflow-hidden')
        }, 300) // Match duration-300
    }

    // Close when clicking backdrop
    closeBackground(event) {
        if (event.target === this.backdropTarget) {
            this.close(event)
        }
    }
}
