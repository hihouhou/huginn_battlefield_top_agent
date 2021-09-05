require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::BattlefieldTopAgent do
  before(:each) do
    @valid_options = Agents::BattlefieldTopAgent.new.default_options
    @checker = Agents::BattlefieldTopAgent.new(:name => "BattlefieldTopAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
