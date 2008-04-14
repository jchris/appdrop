require "form_builder_helper"

module AccessibleForm

  class PAFormBuilder < ActionView::Helpers::FormBuilder

    ActionView::Helpers::AssetTagHelper.register_javascript_include_default("inline_mozilla_hack.js")

    (field_helpers - %w(check_box radio_button) + %w(select)).each do |selector|
      src = <<-END_SRC
        def #{selector}(field, options = {})
          field = field.to_s
          label_text, required, note = extract_paf_options(field, options)
          generic_field(field, super, label_text, {:required => required, :note => note})
        end
        END_SRC
        class_eval src, __FILE__, __LINE__
      end

      %w(check_box radio_button).each do |selector|
        src = <<-END_SRC
       def #{selector}(field, options = {})
         field = field.to_s
         label_text, required, note = extract_paf_options(field, options)
         generic_field(field, super, label_text, {:required => required, :note => note})
       end
       END_SRC
       class_eval src, __FILE__, __LINE__
     end

    def submit(text, options = {})
      generic_field(nil, @template.submit_tag(text, options), nil, options)
    end
    
    def hidden_field(*args)
      super
    end

    def file_column_field(field, options = {})
      field = field.to_s
      label_text, required, note = extract_paf_options(field, options)
      generic_field(field, @template.file_column_field(@object_name, field, options), label_text, {:required => required, :note => note})
    end

    def separator(new_section_name, options = {})
      return options[:html] unless options[:html].blank?
      <<-HTML
    </ol>
  </fieldset>
  <fieldset><legend>#{new_section_name}</legend>
    <ol>
      HTML
    end

    protected
    def generic_field(fieldname, field, label_text = nil, options = {})
      required = options[:required] ? @template.content_tag('span', '*', :class => 'requiredField') : ''
      note = options[:note] ? @template.content_tag('em', " #{options[:note]}") : ''
      unless label_text.blank?
        if options[:label] == :after
          li(field + label(label_text, "#{@object_name}_#{fieldname}", true) + required + note)
        else
          li(
              label(label_text, "#{@object_name}_#{fieldname}") +
              field + required + note
            )
        end
      else # No label
        li(field + required + note)
      end
    end

    def li content, options = {}
      @template.content_tag 'li', content, options
    end

    def label text, for_field, after = false
      @template.content_tag 'label', "#{text}#{after ? '' : ':'}", :for => for_field
    end

    def extract_paf_options field, options
      label_text = options.delete(:label) || field.to_s.humanize
      required = options.delete(:required) || false
      note = options.delete(:note) || false
      [label_text, required, note]
    end
  end

  def a_form_for(object_name, *args, &proc)
    options = args.last.is_a?(Hash) ? args.last : {}
    if options[:html].nil? then
      options[:html] = { :class => "aFrm" }
    else
      options[:html][:class] = (options[:html][:class].nil?) ? "aFrm" : "#{options[:html][:class]} aFrm"
    end
    legend = options.delete :legend
    if legend.blank?
      prefix = options[:prefix].blank? ? "<fieldset><ol>" : options[:prefix]
      postfix = options[:postfix].blank? ? "</fieldset></ol>" : options[:postfix]
    else
      prefix = options[:prefix].blank? ? "<fieldset><legend>#{legend}</legend><ol>" : options[:prefix]
      postfix = options[:postfix].blank? ? '</ol></fieldset>' : options[:postfix]
    end

    custom_form_for(
                   PAFormBuilder, prefix, postfix,
                   form_tag(options.delete(:url) || {}, options.delete(:html) || {}),
                   object_name, *args, &proc)
  end

  def a_remote_form_for(object_name, *args, &proc)
    options = args.last.is_a?(Hash) ? args.last : {}
    if options[:html].nil? then
      options[:html] = { :class => "aFrm" }
    else
      options[:html][:class] = (options[:html][:class].nil?) ? "aFrm" : "#{options[:html][:class]} aFrm"
    end
    legend = options.delete :legend
    if legend.blank?
      prefix = options[:prefix].blank? ? "<fieldset><ol>" : options[:prefix]
      postfix = options[:postfix].blank? ? "</ol></fieldset>" : options[:postfix]
    else
      prefix = options[:prefix].blank? ? "<fieldset><legend>#{legend}</legend><ol>" : options[:prefix]
      postfix = options[:postfix].blank? ? '</ol></fieldset>' : options[:postfix]
    end
    custom_form_for(PAFormBuilder, prefix, postfix, form_remote_tag(options), object_name, *args, &proc)
  end
end


