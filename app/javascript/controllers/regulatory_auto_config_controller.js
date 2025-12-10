import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="regulatory-auto-config"
export default class extends Controller {
    static targets = ["url", "content", "resultsKey", "titleKey", "urlKey", "endpointUrl", "button", "status", "sectors", "jurisdictions"]

    connect() {
        this.originalButtonText = this.buttonTarget.innerText
    }

    async fetchConfig(event) {
        event.preventDefault()

        const docUrl = this.urlTarget.value
        const docContent = this.contentTarget.value

        if (!docUrl && !docContent) {
            alert("Please provide a Documentation URL or paste content first.")
            return
        }

        this.setLoading(true)

        try {
            const response = await fetch("/admin/regulatory_data_sources/preview_config", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
                },
                body: JSON.stringify({
                    documentation_url: docUrl,
                    documentation_content: docContent
                })
            })

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}))
                throw new Error(errorData.error || "Failed to configure source")
            }

            const config = await response.json()
            this.fillForm(config)
            this.setStatus("Success! Configuration applied.", "text-green-600")

        } catch (error) {
            console.error(error)
            this.setStatus(error.message, "text-red-600")
        } finally {
            this.setLoading(false)
        }
    }

    fillForm(config) {
        if (config.url) this.endpointUrlTarget.value = config.url
        if (config.settings) {
            if (config.settings.results_key) this.resultsKeyTarget.value = config.settings.results_key
            if (config.settings.title_key) this.titleKeyTarget.value = config.settings.title_key
            if (config.settings.url_key) this.urlKeyTarget.value = config.settings.url_key
        }

        if (config.sectors && this.hasSectorsTarget) {
            const tagifyController = this.application.getControllerForElementAndIdentifier(this.sectorsTarget, "tagify")
            if (tagifyController) tagifyController.addTags(config.sectors)
        }

        if (config.jurisdictions && this.hasJurisdictionsTarget) {
            const tagifyController = this.application.getControllerForElementAndIdentifier(this.jurisdictionsTarget, "tagify")
            if (tagifyController) tagifyController.addTags(config.jurisdictions)
        }
    }

    setLoading(isLoading) {
        if (isLoading) {
            this.buttonTarget.disabled = true
            this.buttonTarget.innerText = "Analyzing..."
            this.statusTarget.innerText = ""
        } else {
            this.buttonTarget.disabled = false
            this.buttonTarget.innerText = this.originalButtonText
        }
    }

    setStatus(message, colorClass) {
        this.statusTarget.className = `text-sm mt-2 ${colorClass}`
        this.statusTarget.innerText = message
    }
}
