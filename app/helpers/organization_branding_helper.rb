module OrganizationBrandingHelper
  def organization_css_variables
    return {} unless current_user.organization
    
    current_user.organization.css_variables.map do |key, value|
      "#{key}: #{value};"
    end.join("\n")
  end

  def organization_brand_styles
    return "" unless current_user.organization
    
    org = current_user.organization
    <<~CSS
      :root {
        #{organization_css_variables}
      }
      
      .btn-primary {
        background-color: var(--primary-color);
        border-color: var(--primary-color);
      }
      
      .btn-primary:hover {
        background-color: #{darken_color(org.primary_color, 10)};
        border-color: #{darken_color(org.primary_color, 10)};
      }
      
      .btn-secondary {
        background-color: var(--secondary-color);
        border-color: var(--secondary-color);
      }
      
      .text-primary {
        color: var(--primary-color) !important;
      }
      
      .text-secondary {
        color: var(--secondary-color) !important;
      }
      
      .text-accent {
        color: var(--accent-color) !important;
      }
      
      .bg-primary {
        background-color: var(--primary-color) !important;
      }
      
      .bg-secondary {
        background-color: var(--secondary-color) !important;
      }
      
      .bg-accent {
        background-color: var(--accent-color) !important;
      }
      
      .border-primary {
        border-color: var(--primary-color) !important;
      }
      
      .border-secondary {
        border-color: var(--secondary-color) !important;
      }
      
      .border-accent {
        border-color: var(--accent-color) !important;
      }
    CSS
  end

  def organization_logo
    return nil unless current_user.organization&.logo_url.present?
    
    image_tag current_user.organization.logo_url, 
              alt: "#{current_user.organization.name} Logo", 
              class: "h-8 w-auto"
  end

  def organization_favicon
    return nil unless current_user.organization&.favicon_url.present?
    favicon_link_tag current_user.organization.favicon_url
  end

  def organization_welcome_message
    current_user.organization&.welcome_message || "Welcome to #{current_user.organization&.name || 'ComplyFlow'}"
  end

  def organization_timezone
    current_user.organization&.timezone || 'UTC'
  end

  def organization_locale
    current_user.organization&.locale || 'en'
  end

  def organization_currency
    current_user.organization&.currency || 'USD'
  end

  def format_organization_date(date)
    return date unless date
    format = current_user.organization&.date_format || 'MM/DD/YYYY'
    case format
    when 'MM/DD/YYYY'
      date.strftime('%m/%d/%Y')
    when 'DD/MM/YYYY'
      date.strftime('%d/%m/%Y')
    when 'YYYY-MM-DD'
      date.strftime('%Y-%m-%d')
    else
      date.strftime('%m/%d/%Y')
    end
  end

  def format_organization_time(time)
    return time unless time
    format = current_user.organization&.time_format || '12h'
    case format
    when '12h'
      time.strftime('%I:%M %p')
    when '24h'
      time.strftime('%H:%M')
    else
      time.strftime('%I:%M %p')
    end
  end

  def organization_privacy_badge
    return "" unless current_user.organization
    level = current_user.organization.privacy_level
    case level
    when 'high'
      content_tag :span, "High Privacy", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800"
    when 'standard'
      content_tag :span, "Standard Privacy", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
    when 'low'
      content_tag :span, "Low Privacy", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800"
    else
      ""
    end
  end

  def organization_compliance_badges
    return [] unless current_user.organization&.compliance_keywords.present?
    current_user.organization.compliance_keywords.map do |keyword|
      content_tag :span, keyword, 
                  class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 mr-1"
    end
  end

  def organization_retention_info
    return "" unless current_user.organization
    days = current_user.organization.data_retention_days
    years = (days / 365.0).round(1)
    content_tag :div, class: "text-sm text-gray-600" do
      "Data retention: #{years} years (#{days} days)"
    end
  end

  def organization_2fa_status
    return "" unless current_user.organization
    if current_user.organization.require_2fa
      content_tag :span, "2FA Required", 
                  class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
    else
      content_tag :span, "2FA Optional", 
                  class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
    end
  end

  def organization_session_timeout
    return "" unless current_user.organization
    minutes = current_user.organization.session_timeout_minutes
    hours = (minutes / 60.0).round(1)
    content_tag :div, class: "text-sm text-gray-600" do
      "Session timeout: #{hours} hours"
    end
  end

  private

  def darken_color(hex_color, percent)
    # Simple color darkening - in production you might want a more sophisticated color library
    hex_color
  end
end 