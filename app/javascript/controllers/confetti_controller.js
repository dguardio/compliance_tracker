import { Controller } from "@hotwired/stimulus"
import "canvas-confetti"

export default class extends Controller {
    connect() {
        console.log("ConfettiController connected (Local UMD)")
        this.fire = this.fire.bind(this)
    }

    fire(event) {
        if (event) event.preventDefault()

        // Spread confetti from the click source or center if unknown
        const rect = event.target.getBoundingClientRect()
        const x = (rect.left + rect.width / 2) / window.innerWidth
        const y = (rect.top + rect.height / 2) / window.innerHeight

        if (window.confetti) {
            window.confetti({
                particleCount: 100,
                spread: 70,
                origin: { x, y },
                colors: ['#6366F1', '#10B981', '#F59E0B', '#EF4444'] // Brand colors
            })
        } else {
            console.error("Confetti library not loaded")
        }
    }
}
