# frozen_string_literal: true

class Joyful::ToastComponent < ViewComponent::Base
  def initialize(type: :success, message:, title: nil)
    @type = type
    @message = message
    @title = title
  end

  def call
    # This component is intended to be rendered via Turbo Stream or JS, 
    # but can be rendered inline. 
    # It uses Alpine or Stimulus for the slide-in. 
    # For now, let's assume it renders a hidden div that auto-shows using Alpine/Stimulus.
    
    icon_wrapper_class, icon_svg, title_color = case @type
    when :success
      ["bg-success-100 text-success-600", success_icon, "text-gray-900"]
    when :error
      ["bg-danger-100 text-danger-600", error_icon, "text-gray-900"]
    when :warning
      ["bg-warning-100 text-warning-600", warning_icon, "text-gray-900"]
    else
      ["bg-primary-100 text-primary-600", info_icon, "text-gray-900"]
    end

    content_tag :div, 
      class: "pointer-events-auto w-auto max-w-4xl overflow-hidden rounded-lg bg-white shadow-lg ring-1 ring-black ring-opacity-5 transform transition-all duration-300 ease-out-back custom-toast",
      data: { 
        controller: "toast", 
        transition_enter: "transform ease-out duration-300 transition",
        transition_enter_start: "translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2",
        transition_enter_end: "translate-y-0 opacity-100 sm:translate-x-0",
        transition_leave: "transition ease-in duration-100",
        transition_leave_start: "opacity-100",
        transition_leave_end: "opacity-0"
      } do
      content_tag :div, class: "p-6" do
        content_tag :div, class: "flex items-start" do
          concat(content_tag(:div, class: "flex-shrink-0") do
            content_tag(:div, class: "inline-flex items-center justify-center h-10 w-10 rounded-full #{icon_wrapper_class}") do
               raw(icon_svg)
            end
          end)
          
          concat(content_tag(:div, class: "ml-3 flex-1 pt-0.5") do
             concat content_tag(:p, @title || type_title, class: "text-sm font-medium #{title_color}")
             concat content_tag(:p, @message, class: "mt-1 text-sm text-gray-500")
          end)
          
          concat(content_tag(:div, class: "ml-4 flex flex-shrink-0") do
             button_tag(type: "button", class: "inline-flex rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2", data: { action: "click->toast#close" }) do
               raw('<span class="sr-only">Close</span><svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" /></svg>')
             end
          end)
        end
      end
    end
  end

  private

  def type_title
    case @type
    when :success then "Success!"
    when :error then "Oops!"
    when :warning then "Heads up!"
    else "Note"
    end
  end

  def success_icon
    # Party Popper emoji or Check
    '<span class="text-xl">🎉</span>' 
  end

  def error_icon
    '<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" /></svg>'
  end

  def warning_icon
    '<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" /></svg>'
  end
  
  def info_icon
     '<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12v-.008z" /></svg>'
  end
end
