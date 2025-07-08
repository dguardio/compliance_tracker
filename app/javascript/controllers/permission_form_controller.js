import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["granteeType", "granteeId", "resourceType", "resourceId"]

  connect() {
    console.log("Permission form controller connected")
  }

  updateGranteeOptions() {
    const granteeType = this.granteeTypeTarget.value
    const granteeIdSelect = this.granteeIdTarget
    
    if (granteeType) {
      const organizationId = this.element.dataset.organizationId
      fetch(`/organizations/${organizationId}/permissions/get_grantee_options?grantee_type=${granteeType}`)
        .then(response => {
          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`)
          }
          return response.json()
        })
        .then(data => {
          granteeIdSelect.innerHTML = '<option value="">Select a grantee...</option>'
          data.forEach(option => {
            const optionElement = document.createElement('option')
            optionElement.value = option.id
            optionElement.textContent = option.name
            granteeIdSelect.appendChild(optionElement)
          })
        })
        .catch(error => {
          console.error('Error fetching grantee options:', error)
          granteeIdSelect.innerHTML = '<option value="">Error loading options</option>'
        })
    } else {
      granteeIdSelect.innerHTML = '<option value="">Select grantee type first...</option>'
    }
  }

  updateResourceOptions() {
    const resourceType = this.resourceTypeTarget.value
    const resourceIdSelect = this.resourceIdTarget
    
    if (resourceType) {
      const organizationId = this.element.dataset.organizationId
      fetch(`/organizations/${organizationId}/permissions/get_resources?resource_type=${resourceType}`)
        .then(response => {
          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`)
          }
          return response.json()
        })
        .then(data => {
          resourceIdSelect.innerHTML = '<option value="">All resources of this type</option>'
          data.forEach(resource => {
            const optionElement = document.createElement('option')
            optionElement.value = resource.id
            optionElement.textContent = resource.name
            resourceIdSelect.appendChild(optionElement)
          })
        })
        .catch(error => {
          console.error('Error fetching resource options:', error)
          resourceIdSelect.innerHTML = '<option value="">Error loading options</option>'
        })
    } else {
      resourceIdSelect.innerHTML = '<option value="">Select resource type first...</option>'
    }
  }
} 