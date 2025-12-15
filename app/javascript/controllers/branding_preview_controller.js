import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["preview", "logoInput", "primaryColorInput", "secondaryColorInput", "logoPreview", "brandName"]
    static values = {
        defaultLogo: String,
        defaultPrimary: String,
        defaultSecondary: String
    }

    connect() {
        // Initial setup if needed
    }

    updatePreview() {
        // Logo update logic (if url changes)
        if (this.hasLogoInputTarget && this.logoInputTarget.value) {
            // We can't easily preview a URL without loading it, but for now we could try setting background or img src if we had an img target.
            // The mock preview just has a div "Logo".
        }
    }

    // Action for color input change
    updateColor(event) {
        const color = event.target.value
        const type = event.target.dataset.colorType // 'primary', 'secondary', 'accent', 'text'

        // We update the CSS variables on the preview target directly to override inline styles
        if (this.hasPreviewTarget) {
            if (type === 'primary') {
                this.previewTarget.style.setProperty('--preview-primary', color)
            } else if (type === 'secondary') {
                this.previewTarget.style.setProperty('--preview-secondary', color)
            }
            // Add support for accent/text if the preview card uses them (it currently uses primary/secondary mainly)
        }
    }
}
