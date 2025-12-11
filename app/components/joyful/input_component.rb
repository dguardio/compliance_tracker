# frozen_string_literal: true

class Joyful::InputComponent < ViewComponent::Base
  def initialize(form:, method:, label: nil, placeholder: nil, hint: nil, required: false, type: :text_field, **system_arguments)
    @form = form
    @method = method
    @label = label
    @placeholder = placeholder
    @hint = hint
    @required = required
    @type = type
    @system_arguments = system_arguments
  end

  def call
    # Check for errors on the object for this method
    errors = @form.object&.errors&.[](@method)
    has_error = errors.present?

    # Base classes for the input
    input_classes = "block w-full rounded-xl border-0 py-3 px-4 text-gray-900 shadow-sm ring-1 ring-inset placeholder:text-gray-400 focus:ring-2 focus:ring-inset sm:text-sm sm:leading-6 transition-all duration-200"
    
    # State-based classes
    if has_error
       # Error State: Border turns Coral (danger), Shake animation (handled by stimulus or CSS if simple)
       state_classes = "bg-danger-50 ring-danger-300 focus:ring-danger-500 animate-shake"
    else
       # Default State: Light background, focus white
       state_classes = "bg-slate-50 ring-slate-200 focus:bg-white focus:ring-primary-500"
    end

    final_classes = class_names(input_classes, state_classes, @system_arguments[:class])
    
    # Merge system arguments, ensuring we don't double-up on class or placeholder if passed in args
    input_options = @system_arguments.except(:class).merge({
      class: final_classes,
      placeholder: @placeholder,
      required: @required
    })

    content_tag :div, class: "space-y-1" do
      concat @form.label(@method, @label, class: "block text-sm font-medium leading-6 text-gray-900") if @label
      
      # Dynamically call the correct input method with appropriate arguments
      case @type
      when :collection_select
        # collection_select(object, method, collection, value_method, text_method, options = {}, html_options = {})
        # We expect these keys in @system_arguments
        collection = @system_arguments[:collection]
        value_method = @system_arguments[:value_method]
        text_method = @system_arguments[:text_method]
        options = @system_arguments[:options] || {}
        html_options = @system_arguments[:html_options] || {}
        
        # Merge our default classes into html_options
        html_options[:class] = class_names(final_classes, html_options[:class])
        
        concat @form.collection_select(@method, collection, value_method, text_method, options, html_options)
        
      when :select
        # select(object, method, choices = nil, options = {}, html_options = {})
        choices = @system_arguments[:choices]
        options = @system_arguments[:options] || {}
        html_options = @system_arguments[:html_options] || {}
        
        # Merge our default classes into html_options
        html_options[:class] = class_names(final_classes, html_options[:class])
        
        concat @form.select(@method, choices, options, html_options)
        
      else
        # Standard inputs (text_field, password_field, etc.)
        # input_options was created above by merging system arguments
        concat @form.public_send(@type, @method, input_options)
      end

      if has_error
        concat content_tag(:p, errors.first, class: "mt-1 text-sm text-danger-600 animate-pulse") 
      elsif @hint
        concat content_tag(:p, @hint, class: "mt-1 text-sm text-gray-500")
      end
    end
  end
end

