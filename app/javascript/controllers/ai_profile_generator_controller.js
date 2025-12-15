import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        id: String,
        url: String
    }
    static targets = ["button", "icon", "spinner", "industries", "keywords", "exclusions"]

    connect() {
        // console.log("AI Generator Connected")
    }

    async generate(event) {
        event.preventDefault()

        // UI State: Loading
        this.buttonTarget.disabled = true
        this.iconTarget.classList.add("hidden")
        this.spinnerTarget.classList.remove("hidden")
        this.buttonTarget.classList.add("opacity-75", "cursor-wait")

        try {
            const token = document.querySelector('meta[name="csrf-token"]').content

            const response = await fetch(this.urlValue, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": token
                },
                body: JSON.stringify({ organization_id: this.idValue })
            })

            if (!response.ok) throw new Error("Network response was not ok")

            const data = await response.json()

            this.fillData(data)
            this.showSuccess()

        } catch (error) {
            console.error("AI Generation Error:", error)
            this.showError()
        } finally {
            // UI State: Reset
            this.buttonTarget.disabled = false
            this.iconTarget.classList.remove("hidden")
            this.spinnerTarget.classList.add("hidden")
            this.buttonTarget.classList.remove("opacity-75", "cursor-wait")
        }
    }

    fillData(data) {
        // Assuming inputs are standard OR tagify. 
        // If standard text inputs/areas:
        // this.industriesTarget.value = data.industries.join(", ")

        // For Tagify (which expects comma-separated value in the input to init tags, OR adding tags via method)
        // We will update the value and dispatch a change event in case Tagify is listening,
        // OR directly access the Tagify instance if we could.
        // Simplest way: update underlying input value and fire change event.

        if (data.industries) {
            this.industriesTarget.value = data.industries.join(", ")
            // If tagify controller is listening to changes on the input or if we need to manually trigger:
            this.industriesTarget.dispatchEvent(new Event('change', { bubbles: true }))

            // HACK: If Tagify is present, we might need to manually tell it to add tags if simple value change doesn't work.
            // But standard Tagify usually syncs with input value on load. 
            // For dynamic updates, dispatching 'change' is often enough if the controller handles it.
            // Our tagify_controller.js doesn't seem to observe changes, but let's assume standard form behavior for now.
            if (this.industriesTarget._tagify) {
                this.industriesTarget._tagify.removeAllTags()
                this.industriesTarget._tagify.addTags(data.industries)
            }
        }

        if (data.keywords) {
            this.keywordsTarget.value = data.keywords.join(", ")
            if (this.keywordsTarget._tagify) {
                this.keywordsTarget._tagify.removeAllTags()
                this.keywordsTarget._tagify.addTags(data.keywords)
            }
        }

        if (data.exclusion_terms) {
            this.exclusionsTarget.value = data.exclusion_terms.join(", ")
            if (this.exclusionsTarget._tagify) {
                this.exclusionsTarget._tagify.removeAllTags()
                this.exclusionsTarget._tagify.addTags(data.exclusion_terms)
            }
        }
    }

    showSuccess() {
        // Optional: Flash a success message or trigger confetti
        const toast = document.createElement("div")
        // ... minimal toast logic ... or rely on visual fill
    }

    showError() {
        alert("Failed to generate profile. Please try again.")
    }
}
