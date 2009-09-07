Factory.define :<%= file_name %> do |factory|
<%- attributes.each do |attribute| -%>
  <%= factory_line(attribute) %>
<%- end -%>
end
