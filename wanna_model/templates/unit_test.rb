require File.join(File.dirname(__FILE__), '..', 'test_helper')

class <%= class_name %>Test < ActiveSupport::TestCase
<%- attributes.each do |attribute| -%>
  <%- if attribute.reference? -%>
  should_belong_to  :<%= attribute.name %>
  should_have_index :<%= attribute.name %>_id
  <%- end -%>
<%- end -%>
end
