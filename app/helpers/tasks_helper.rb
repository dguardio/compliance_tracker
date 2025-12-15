module TasksHelper
  def priority_color_class(priority)
    case priority.to_s.downcase
    when 'high', 'critical'
      'border-danger-500'
    when 'medium'
      'border-warning-500'
    when 'low'
      'border-success-500'
    else
      'border-gray-200'
    end
  end
end
