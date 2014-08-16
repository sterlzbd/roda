require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

begin
  require 'tilt/erb'
  begin
    require 'tilt/erubis'
  rescue LoadError
    # Tilt 1 support
  end
rescue LoadError
  warn "tilt or erubis not installed, skipping _erubis_escaping plugin test"  
else
describe "_erubis_escaping plugin" do
  before do
    app(:bare) do
      plugin :render, :escape=>true

      route do |r|
        render(:inline=>'<%= "<>" %> <%== "<>" %><%= "<>" if false %>')
      end
    end
  end

  it "should escape inside <%= %> and not inside <%== %>, and handle postfix conditionals" do
    body.should == '&lt;&gt; <>'
  end
end
end
