# frozen_string_literal: true

require_relative './plan_maker'

Dir["#{__dir__}/modules/*.rb"].each do |fn|
  require_relative fn
end

def plan(&block)
  PlanMaker.plan(&block)
end

def if_exe(exe)
  exe_found = `which #{exe} 2>/dev/null`.strip != ''
  return unless exe_found

  yield
end
