require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "indifferent_params plugin" do 
  it "allows indifferent access to request params via params method" do
    app(:bare) do
      plugin :indifferent_params

      route do |r|
        r.on do
          "#{params[:a]}/#{params[:b][0][:c]}"
        end
      end
    end

    body('QUERY_STRING'=>'a=2&b[][c]=3', 'rack.input'=>StringIO.new).should == '2/3'
  end
end
