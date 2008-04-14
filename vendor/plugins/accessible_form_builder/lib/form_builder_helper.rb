# Create the +form_for+ and +remote_form_for+ methods for a particular
# form builder.
# from rubaidh.com's tabular form builder
def custom_form_for(builder, fields_pre, fields_post, form_tag, object_name, *args, &proc)
  raise ArgumentError, "Missing block" unless block_given?
  options = args.last.is_a?(Hash) ? args.pop : {}
  concat(form_tag, proc.binding)
  concat(fields_pre, proc.binding)
  fields_for(object_name, *(args << options.merge(:builder => builder)), &proc)
  concat(fields_post, proc.binding)
  concat("</form>", proc.binding)
end
