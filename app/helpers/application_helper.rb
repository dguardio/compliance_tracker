module ApplicationHelper
  include JsonHelper

  def organization_css_variables
    return unless current_user&.organization

    variables = current_user.organization.css_variables
    variables.map { |key, value| "#{key}: #{value};" }.join(" ")
  end

  def organization_logo(css_class: "h-8 w-auto")
    if current_user&.organization&.logo_url.present?
      image_tag current_user.organization.logo_url, class: css_class, alt: current_user.organization.name
    else
      # Generic logo placeholder
      content_tag :div, class: "flex items-center justify-center bg-indigo-600 text-white rounded-lg #{css_class.gsub('w-auto', 'w-8')}" do
        content_tag :i, nil, class: "fas fa-shield-alt"
      end
    end
  end

  def organization_favicon
    return unless current_user&.organization&.favicon_url.present?
    
    favicon_link_tag current_user.organization.favicon_url
  end
end