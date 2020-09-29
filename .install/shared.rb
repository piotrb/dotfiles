# frozen_string_literal: true

require_relative './plan_maker'

Dir["#{__dir__}/modules/*.rb"].each do |fn|
  require_relative fn
end

def plan(&block)
  PlanMaker.plan(&block)
end
